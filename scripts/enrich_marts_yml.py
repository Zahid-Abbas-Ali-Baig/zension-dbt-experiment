"""Enrich codegen marts YAML with descriptions, KPI linkage, and data tests."""
from __future__ import annotations

import re
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "target" / "codegen_marts_models.yml"
DST = ROOT / "models" / "marts" / "_marts__models.yml"

MODEL_META: dict[str, dict] = {
    "fct_orders": {
        "description": "Order-level sales fact. One row per commercial order with GMV, partner/program context, and fulfillment flags.",
        "pk": "order_id",
        "kpis": ["order_count", "gmv_sar", "preorder_order_share", "avg_days_payment_to_delivery", "median_order_to_delivery_days"],
        "fks": {
            "customer_id": "dim_customers",
            "program_id": "dim_programs",
            "channel_partner_id": "dim_channel_partners",
        },
    },
    "fct_order_items": {
        "description": "Order line-item fact with resolved device SKU attributes for product mix analysis.",
        "pk": "order_item_id",
        "kpis": ["order_item_count"],
        "fks": {
            "order_id": "fct_orders",
            "customer_id": "dim_customers",
            "program_id": "dim_programs",
            "channel_partner_id": "dim_channel_partners",
            "master_sku_id": "dim_device_skus",
        },
    },
    "dim_customers": {
        "description": "Customer dimension with Nafath/mobile verification, CEP employer link, and device counts.",
        "pk": "customer_id",
        "kpis": ["verified_customer_count", "avg_devices_per_customer"],
        "fks": {"corporate_company_id": "dim_corporate_companies"},
    },
    "dim_channel_partners": {
        "description": "Channel partner dimension (Jarir, ZAAM, Axiom, etc.) with API operations rollups.",
        "pk": "channel_partner_id",
        "kpis": [],
        "fks": {},
    },
    "dim_programs": {
        "description": "Commercial program dimension with subscription limits and utilization.",
        "pk": "program_id",
        "kpis": ["program_subscription_utilization_pct", "programs_over_limit_count"],
        "fks": {"channel_partner_id": "dim_channel_partners"},
    },
    "dim_corporate_companies": {
        "description": "CEP employer dimension with verified customer rollups.",
        "pk": "corporate_company_id",
        "kpis": ["verified_customer_count"],
        "fks": {},
    },
    "dim_device_skus": {
        "description": "Master device SKU dimension (brand, model, memory, color).",
        "pk": "master_sku_id",
        "kpis": ["order_item_count"],
        "fks": {},
    },
    "dim_dates": {
        "description": "Calendar dimension generated via dbt_utils.date_spine for time-based reporting.",
        "pk": "date_key",
        "kpis": [],
        "fks": {},
        "time_spine": {"standard_granularity_column": "full_date"},
    },
    "fct_subscriptions": {
        "description": "Subscription lifecycle fact with MRR eligibility and term months.",
        "pk": "subscription_id",
        "kpis": ["subscription_count", "active_subscription_count", "mrr_sar", "avg_subscription_term_months", "upgrade_rate"],
        "fks": {
            "customer_id": "dim_customers",
            "order_id": "fct_orders",
            "channel_partner_id": "dim_channel_partners",
            "program_id": "dim_programs",
            "subscription_pricing_id": "dim_subscription_pricing",
        },
    },
    "fct_subscription_monthly_snapshots": {
        "description": "Month-end subscription status snapshots for churn and cohort analysis.",
        "pk": ["subscription_id", "snapshot_month"],
        "kpis": ["churn_rate"],
        "fks": {
            "subscription_id": "fct_subscriptions",
            "channel_partner_id": "dim_channel_partners",
            "program_id": "dim_programs",
        },
    },
    "dim_subscription_pricing": {
        "description": "Subscription price list dimension with MRR rollups.",
        "pk": "subscription_pricing_id",
        "kpis": ["mrr_sar"],
        "fks": {},
    },
    "dim_subscription_durations": {
        "description": "Subscription term option dimension in months.",
        "pk": "subscription_duration_id",
        "kpis": ["avg_subscription_term_months"],
        "fks": {"program_id": "dim_programs", "channel_partner_id": "dim_channel_partners"},
    },
    "fct_payments": {
        "description": "CRM payment fact unified with PSP reconciliation status.",
        "pk": "payment_id",
        "kpis": ["collected_revenue_sar", "avg_days_payment_to_delivery"],
        "fks": {
            "order_id": "fct_orders",
            "customer_id": "dim_customers",
            "program_id": "dim_programs",
            "channel_partner_id": "dim_channel_partners",
            "invoice_id": "fct_invoices",
            "subscription_id": "fct_subscriptions",
        },
    },
    "fct_payment_attempts": {
        "description": "Payment attempt / card capture fact for failure and retry analysis.",
        "pk": "payment_history_id",
        "kpis": ["payment_failure_rate", "customers_with_outstanding_payments"],
        "fks": {
            "payment_id": "fct_payments",
            "order_id": "fct_orders",
            "customer_id": "dim_customers",
            "program_id": "dim_programs",
            "channel_partner_id": "dim_channel_partners",
        },
    },
    "fct_psp_transactions": {
        "description": "Payment Service transaction fact with retry-queue segmentation.",
        "pk": "transaction_id",
        "kpis": ["customers_on_retry_count"],
        "fks": {},
    },
    "dim_payment_methods": {
        "description": "Conformed CRM and PSP payment methods with expiry health.",
        "pk": "payment_method_key",
        "kpis": ["expired_payment_method_count"],
        "fks": {},
    },
    "fct_invoices": {
        "description": "Zoho-synced invoice fact (CRM-sourced).",
        "pk": "invoice_id",
        "kpis": ["invoiced_revenue_sar", "customers_with_outstanding_payments"],
        "fks": {
            "customer_id": "dim_customers",
            "channel_partner_id": "dim_channel_partners",
            "program_id": "dim_programs",
        },
    },
    "fct_invoice_line_items": {
        "description": "Invoice line-item fact linked to subscriptions.",
        "pk": "invoice_line_item_id",
        "kpis": [],
        "fks": {
            "invoice_id": "fct_invoices",
            "subscription_id": "fct_subscriptions",
            "customer_id": "dim_customers",
        },
    },
    "fct_credit_notes": {
        "description": "Credit note fact synced from Zoho via CRM.",
        "pk": "credit_note_id",
        "kpis": ["credit_note_count"],
        "fks": {
            "invoice_id": "fct_invoices",
            "customer_id": "dim_customers",
            "channel_partner_id": "dim_channel_partners",
            "program_id": "dim_programs",
        },
    },
    "fct_finance_reconciliation_monthly": {
        "description": "Monthly finance reconciliation of collected vs invoiced revenue.",
        "pk": "reconciliation_month",
        "kpis": ["finance_variance_sar", "collected_revenue_sar", "invoiced_revenue_sar"],
        "fks": {},
    },
    "fct_devices": {
        "description": "Physical device asset fact for fulfillment and per-customer device analytics.",
        "pk": "device_id",
        "kpis": ["avg_devices_per_customer"],
        "fks": {
            "order_item_id": "fct_order_items",
            "order_id": "fct_orders",
            "customer_id": "dim_customers",
            "subscription_id": "fct_subscriptions",
            "program_id": "dim_programs",
            "channel_partner_id": "dim_channel_partners",
        },
    },
    "fct_device_journey_events": {
        "description": "Sparse device journey milestone events supplementing delivery SLA.",
        "pk": "device_journey_id",
        "kpis": [],
        "fks": {
            "device_id": "fct_devices",
            "order_id": "fct_orders",
            "customer_id": "dim_customers",
            "subscription_id": "fct_subscriptions",
        },
    },
    "fct_partner_api_events": {
        "description": "Partner webhook / API proxy event fact.",
        "pk": "api_log_id",
        "kpis": ["partner_api_failure_rate"],
        "fks": {"channel_partner_id": "dim_channel_partners"},
    },
    "bridge_cp_skus": {
        "description": "Bridge table mapping channel-partner SKUs to Zaam and master SKUs.",
        "pk": "cp_sku_id",
        "kpis": [],
        "fks": {
            "channel_partner_id": "dim_channel_partners",
            "master_sku_id": "dim_device_skus",
        },
    },
    "fct_refunds": {
        "description": "Unified CRM and PSP refund events with deduplication key.",
        "pk": "refund_id",
        "kpis": ["refund_amount_sar"],
        "fks": {
            "customer_id": "dim_customers",
            "order_id": "fct_orders",
            "channel_partner_id": "dim_channel_partners",
            "program_id": "dim_programs",
        },
        "extra_columns": [
            {"name": "refund_id", "data_type": "text", "description": "Surrogate primary key (refund dedup hash)."},
            {"name": "refund_event_id", "data_type": "text", "description": "Source-system refund event identifier."},
            {"name": "refund_source", "data_type": "text", "description": "Origin system: crm or psp."},
            {"name": "refund_amount_sar", "data_type": "numeric", "description": "Refund amount in SAR."},
            {"name": "refund_date", "data_type": "date", "description": "Refund event date."},
            {"name": "refunded_at", "data_type": "timestamp with time zone", "description": "Refund timestamp."},
            {"name": "customer_id", "data_type": "text", "description": "FK to dim_customers."},
            {"name": "order_id", "data_type": "text", "description": "FK to fct_orders."},
            {"name": "channel_partner_id", "data_type": "text", "description": "FK to dim_channel_partners."},
            {"name": "program_id", "data_type": "text", "description": "FK to dim_programs."},
            {"name": "partner_name", "data_type": "text", "description": "Partner name at time of refund."},
        ],
    },
}

COLUMN_HINTS: dict[str, str] = {
    "order_id": "Natural key for the commercial order.",
    "customer_id": "FK to dim_customers.",
    "program_id": "FK to dim_programs.",
    "channel_partner_id": "FK to dim_channel_partners.",
    "gmv_amount_sar": "Gross merchandise value in SAR (tax inclusive).",
    "is_gmv_eligible": "True when order is not voided/cancelled/rejected/expired.",
    "monthly_recurring_amount_sar": "Monthly subscription amount in SAR from pricing dimension.",
    "is_mrr_eligible": "Active subscription with service start and valid pricing.",
    "collected_amount_sar": "Tax-inclusive collected payment amount in SAR.",
    "invoice_amount_sar": "Total invoice amount in SAR (CRM/Zoho-synced).",
    "is_fully_verified": "Customer passed Nafath and mobile OTP verification.",
    "is_over_subscription_limit": "Program active subs exceed subscription_limit.",
    "is_failure": "API call returned failure status.",
    "refund_amount_sar": "Refund amount in SAR.",
}


def fk_field_name(to_model: str) -> str:
    mapping = {
        "dim_customers": "customer_id",
        "dim_programs": "program_id",
        "dim_channel_partners": "channel_partner_id",
        "dim_corporate_companies": "corporate_company_id",
        "dim_device_skus": "master_sku_id",
        "fct_orders": "order_id",
        "fct_subscriptions": "subscription_id",
        "fct_payments": "payment_id",
        "fct_invoices": "invoice_id",
        "fct_order_items": "order_item_id",
        "fct_devices": "device_id",
        "dim_subscription_pricing": "subscription_pricing_id",
    }
    return mapping.get(to_model, "id")


def enrich_column(
    col: dict,
    model_name: str,
    pk: str | list[str],
    fks: dict[str, str],
) -> dict:
    name = col["name"]
    if not col.get("description"):
        col["description"] = COLUMN_HINTS.get(name, "")
    pks = pk if isinstance(pk, list) else [pk]
    is_composite_pk = isinstance(pk, list)
    tests: list = list(col.get("data_tests", col.get("tests", [])))
    if name in pks:
        if not is_composite_pk:
            for t in ("unique", "not_null"):
                if t not in tests and not any(isinstance(x, dict) and t in x for x in tests):
                    tests.append(t)
        elif "not_null" not in tests:
            tests.append("not_null")
    if name == "full_date" and fks == {} and "granularity" not in col:
        col["granularity"] = "day"
    if name in fks:
        to_model = fks[name]
        tests.append({
            "relationships": {
                "to": f"ref('{to_model}')",
                "field": fk_field_name(to_model),
            }
        })
    if tests:
        col["data_tests"] = tests
    return col


def build_model_tests(meta: dict) -> list:
    pk = meta["pk"]
    if isinstance(pk, list):
        return [{
            "dbt_utils.unique_combination_of_columns": {
                "combination_of_columns": pk,
            }
        }]
    return []


def main() -> None:
    raw = yaml.safe_load(SRC.read_text(encoding="utf-8"))
    models_out = []
    for model in raw["models"]:
        name = model["name"]
        meta = MODEL_META[name]
        kpi_note = ", ".join(meta["kpis"]) if meta["kpis"] else "supporting"
        model["description"] = (
            f"{meta['description']} KPI linkage: {kpi_note}."
        )
        if meta.get("time_spine"):
            model["time_spine"] = meta["time_spine"]
        if name == "fct_refunds" and meta.get("extra_columns"):
            model["columns"] = meta["extra_columns"]
        fks = meta.get("fks", {})
        for col in model.get("columns", []):
            enrich_column(col, name, meta["pk"], fks)
        model_tests = build_model_tests(meta)
        if model_tests:
            model["data_tests"] = model_tests
        models_out.append(model)

    payload = {"version": 2, "models": models_out}
    DST.write_text(yaml.dump(payload, sort_keys=False, allow_unicode=True), encoding="utf-8")
    print(f"Wrote {DST}")


if __name__ == "__main__":
    main()
