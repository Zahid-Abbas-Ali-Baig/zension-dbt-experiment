"""Generate staging model YAML with tests from SQL files."""

from __future__ import annotations

import re
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]

FK_FIELD = {
    "stg_crm__accounts": "customer_id",
    "stg_crm__tos_corporate_company": "corporate_company_id",
    "stg_crm__tos_channel_partners": "channel_partner_id",
    "stg_crm__tos_programs": "program_id",
    "stg_crm__tos_orders": "order_id",
    "stg_crm__tos_order_items": "order_item_id",
    "stg_crm__tos_zaam_skus": "zaam_sku_id",
    "stg_crm__tos_cp_skus": "cp_sku_id",
    "stg_crm__tos_subscription_pricing": "subscription_pricing_id",
    "stg_crm__tos_subscription_durations": "subscription_duration_id",
    "stg_crm__tos_payment_methods": "payment_method_id",
    "stg_crm__aos_invoices": "invoice_id",
    "stg_crm__tos_subscriptions": "subscription_id",
    "stg_crm__tos_master_skus": "master_sku_id",
    "stg_crm__tos_devices": "device_id",
    "stg_crm__tos_countries": "country_id",
    "stg_crm__tos_payments": "payment_id",
    "stg_payments__payments": "psp_payment_id",
    "stg_payments__subscribers": "subscriber_id",
    "stg_payments__subscriptions": "psp_subscription_id",
    "stg_payments__payment_methods": "psp_payment_method_id",
}

META = {
    "stg_crm__accounts": {
        "pk": "customer_id",
        "desc": "SuiteCRM customer accounts with Nafath and mobile verification for KSA identity onboarding.",
        "fks": {
            "corporate_company_id": "stg_crm__tos_corporate_company",
            "channel_partner_id": "stg_crm__tos_channel_partners",
            "program_id": "stg_crm__tos_programs",
        },
    },
    "stg_crm__tos_orders": {
        "pk": "order_id",
        "desc": "Commercial orders placed through Zaam channel partners; one row per order.",
        "fks": {
            "customer_id": "stg_crm__accounts",
            "program_id": "stg_crm__tos_programs",
            "payment_method_id": "stg_crm__tos_payment_methods",
        },
        "accepted": {
            "order_status": [
                "cancelled",
                "delivered",
                "expired",
                "rejected",
                "waiting_for_delivery",
            ],
            "order_type": ["order", "pre-order", "unknown"],
        },
    },
    "stg_crm__tos_order_items": {
        "pk": "order_item_id",
        "desc": "Order line items linking orders to Zaam or channel-partner SKUs.",
        "fks": {
            "order_id": "stg_crm__tos_orders",
            "zaam_sku_id": "stg_crm__tos_zaam_skus",
            "cp_sku_id": "stg_crm__tos_cp_skus",
            "customer_id": "stg_crm__accounts",
        },
    },
    "stg_crm__tos_subscriptions": {
        "pk": "subscription_id",
        "desc": "Device subscriptions with lifecycle status for MRR, churn, and upgrade analytics.",
        "fks": {
            "subscription_pricing_id": "stg_crm__tos_subscription_pricing",
            "channel_partner_id": "stg_crm__tos_channel_partners",
            "customer_id": "stg_crm__accounts",
            "order_id": "stg_crm__tos_orders",
            "order_item_id": "stg_crm__tos_order_items",
            "upgraded_subscription_id": "stg_crm__tos_subscriptions",
        },
        "accepted": {
            "subscription_status": [
                "active",
                "cancelled",
                "upgraded",
                "waiting_for_delivery",
            ]
        },
    },
    "stg_crm__tos_devices": {
        "pk": "device_id",
        "desc": "Physical device assets with brand, model, memory, and color for fulfillment analytics.",
        "fks": {
            "order_item_id": "stg_crm__tos_order_items",
            "zaam_sku_id": "stg_crm__tos_zaam_skus",
        },
    },
    "stg_crm__tos_payments": {
        "pk": "payment_id",
        "desc": "CRM payment records bridging orders, invoices, and Payment Service intents.",
        "fks": {
            "order_id": "stg_crm__tos_orders",
            "invoice_id": "stg_crm__aos_invoices",
            "customer_id": "stg_crm__accounts",
            "subscription_id": "stg_crm__tos_subscriptions",
            "psp_payment_id": "stg_payments__payments",
        },
        "accepted": {
            "payment_status": [
                "cancelled",
                "failed",
                "not_invoiced",
                "paid",
                "refunded",
            ]
        },
    },
    "stg_crm__tos_payment_history": {
        "pk": "payment_history_id",
        "desc": "Payment attempt and card capture events for recurring failure and retry analysis.",
        "fks": {
            "payment_id": "stg_crm__tos_payments",
            "payment_method_id": "stg_crm__tos_payment_methods",
        },
        "accepted": {
            "payment_attempt_status": ["approved", "failed", "paid", "success"]
        },
    },
    "stg_crm__aos_invoices": {
        "pk": "invoice_id",
        "desc": "Zoho-synced CRM invoices for collected vs invoiced revenue reconciliation.",
        "fks": {
            "billing_account_id": "stg_crm__accounts",
            "customer_id": "stg_crm__accounts",
            "channel_partner_id": "stg_crm__tos_channel_partners",
            "program_id": "stg_crm__tos_programs",
        },
        "accepted": {"invoice_status": ["paid", "unpaid"]},
    },
    "stg_crm__tos_invoice_line_items": {
        "pk": "invoice_line_item_id",
        "desc": "Invoice line items with VAT amounts linked to subscriptions.",
        "fks": {
            "subscription_id": "stg_crm__tos_subscriptions",
            "order_item_id": "stg_crm__tos_order_items",
        },
    },
    "stg_crm__tos_credit_notes": {
        "pk": "credit_note_id",
        "desc": "Credit notes synced to Zoho Books for refund and adjustment reporting.",
        "fks": {"invoice_id": "stg_crm__aos_invoices"},
    },
    "stg_crm__tos_channel_partners": {
        "pk": "channel_partner_id",
        "desc": "B2B channel partners (Jarir, ZAAM, Axiom) governing partner-scoped analytics.",
        "fks": {"country_id": "stg_crm__tos_countries"},
        "accepted": {"partner_type": ["ecommerce", "retailer"]},
    },
    "stg_crm__tos_programs": {
        "pk": "program_id",
        "desc": "Commercial programs with subscription limits and partner commercial terms.",
        "fks": {"channel_partner_id": "stg_crm__tos_channel_partners"},
        "accepted": {"program_status": ["active"]},
    },
    "stg_crm__tos_corporate_company": {
        "pk": "corporate_company_id",
        "desc": "CEP employer entities with allowed email domains for employee verification.",
        "fks": {"channel_partner_id": "stg_crm__tos_channel_partners"},
    },
    "stg_crm__tos_master_skus": {
        "pk": "master_sku_id",
        "desc": "Master device SKU catalog for top-model sales analytics.",
        "fks": {},
    },
    "stg_crm__tos_zaam_skus": {
        "pk": "zaam_sku_id",
        "desc": "Zaam program SKUs mapped to master device attributes.",
        "fks": {"master_sku_id": "stg_crm__tos_master_skus"},
    },
    "stg_crm__tos_cp_skus": {
        "pk": "cp_sku_id",
        "desc": "Channel-partner to Zaam SKU bridge for partner-specific catalog pricing.",
        "fks": {
            "channel_partner_id": "stg_crm__tos_channel_partners",
            "zaam_sku_id": "stg_crm__tos_zaam_skus",
            "master_sku_id": "stg_crm__tos_master_skus",
        },
    },
    "stg_crm__tos_subscription_pricing": {
        "pk": "subscription_pricing_id",
        "desc": "Subscription price list; monthly_subscription_amount_sar is the MRR source of truth.",
        "fks": {
            "zaam_sku_id": "stg_crm__tos_zaam_skus",
            "subscription_duration_id": "stg_crm__tos_subscription_durations",
        },
    },
    "stg_crm__tos_subscription_durations": {
        "pk": "subscription_duration_id",
        "desc": "Subscription term options in months linked to programs and partners.",
        "fks": {
            "program_id": "stg_crm__tos_programs",
            "channel_partner_id": "stg_crm__tos_channel_partners",
        },
    },
    "stg_crm__tos_addresses": {
        "pk": "address_id",
        "desc": "Customer addresses for regional order-to-delivery SLA analysis.",
        "fks": {"customer_id": "stg_crm__accounts"},
    },
    "stg_crm__tos_payment_methods": {
        "pk": "payment_method_id",
        "desc": "CRM stored payment methods including card expiry for collections risk.",
        "fks": {"customer_id": "stg_crm__accounts"},
    },
    "stg_crm__tos_countries": {
        "pk": "country_id",
        "desc": "Country reference with VAT rate and Zoho tax IDs for KSA finance compliance.",
        "fks": {},
    },
    "stg_crm__tos_api_logs": {
        "pk": "api_log_id",
        "desc": "Partner API and webhook call logs for operational failure monitoring.",
        "fks": {},
        "accepted": {"api_status": ["failure", "success"]},
    },
    "stg_crm__tos_devices_journey": {
        "pk": "device_journey_id",
        "desc": "Device movement milestones supplementing fulfillment SLA metrics.",
        "fks": {"device_id": "stg_crm__tos_devices"},
    },
    "stg_payments__payments": {
        "pk": "psp_payment_id",
        "desc": "Payment Service payment intents for CRM-to-PSP reconciliation.",
        "fks": {
            "subscriber_id": "stg_payments__subscribers",
            "psp_subscription_id": "stg_payments__subscriptions",
        },
    },
    "stg_payments__transactions": {
        "pk": "transaction_id",
        "desc": "PSP transaction outcomes for payment failure rate and retry queue metrics.",
        "fks": {"subscriber_id": "stg_payments__subscribers"},
        "accepted": {
            "process_status": ["completed", "failed", "in_progress", "queued"],
            "request_status": [
                "authorized",
                "failed",
                "internal_error",
                "required_authentication",
                "success",
                "voided",
            ],
        },
        "accepted_where": {
            "request_status": "request_status is not null and request_status != ''"
        },
    },
    "stg_payments__refunds": {
        "pk": "refund_record_id",
        "desc": "PSP refund events for refund volume reporting.",
        "fks": {},
        "accepted": {"refund_status": ["approved"]},
    },
    "stg_payments__subscribers": {
        "pk": "subscriber_id",
        "desc": "Payment Service subscribers (Stripe-backed) for PSP-side reconciliation.",
        "fks": {"default_payment_method_id": "stg_payments__payment_methods"},
    },
    "stg_payments__subscriptions": {
        "pk": "psp_subscription_id",
        "desc": "PSP recurring subscription records without a native CRM foreign key.",
        "fks": {"subscriber_id": "stg_payments__subscribers"},
    },
    "stg_payments__payment_methods": {
        "pk": "psp_payment_method_id",
        "desc": "Card-on-file payment methods stored at the Payment Service.",
        "fks": {"subscriber_id": "stg_payments__subscribers"},
    },
}

# Relationship tests that expect orphan FK rows per design brief or soft-delete filtering.
WARN_RELATIONSHIPS = {
    ("stg_crm__tos_payments", "psp_payment_id"),
    ("stg_crm__tos_payment_history", "payment_method_id"),
    ("stg_crm__tos_payment_history", "payment_id"),
    ("stg_crm__tos_invoice_line_items", "order_item_id"),
    ("stg_crm__tos_subscriptions", "order_id"),
    ("stg_crm__tos_payment_methods", "customer_id"),
    ("stg_payments__payments", "subscriber_id"),
    ("stg_payments__payments", "psp_subscription_id"),
    ("stg_payments__subscriptions", "subscriber_id"),
    ("stg_payments__transactions", "subscriber_id"),
    ("stg_payments__subscribers", "default_payment_method_id"),
    ("stg_payments__payment_methods", "subscriber_id"),
}

COL_DESC = {
    "created_at": "Timestamp when the source record was created in SuiteCRM or the Payment Service.",
    "updated_at": "Timestamp when the source record was last modified.",
    "_etl_synced_at": "Warehouse ETL sync timestamp; excluded from marts.",
    "_etl_source_system": "Originating source system label from ETL metadata.",
    "is_gmv_eligible": "True when the order is not voided (cancelled, rejected, or expired) per revenue KPI rules.",
    "is_mrr_eligible": "True for active subscriptions with a service start date; excludes pre-delivery subs from MRR.",
    "is_fully_verified": "Customer has both Nafath and mobile OTP verification per program rules.",
    "is_fnf_program": "Flags Friends-and-Family programs pending stakeholder reporting rules.",
    "device_sku_key": "Surrogate key concatenating brand, model, memory, and color for device analytics.",
}


def cols_from_sql(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    match = re.search(r"select\s+(.*?)\s+from\s+source", text, re.S | re.I)
    if not match:
        return []
    names: list[str] = []
    for line in match.group(1).splitlines():
        line = line.strip().rstrip(",")
        if not line or line.startswith("--"):
            continue
        alias = re.search(r"\bas\s+([a-zA-Z0-9_]+)\s*$", line, re.I)
        if alias:
            names.append(alias.group(1))
        elif re.match(r"^[a-zA-Z_][a-zA-Z0-9_]*$", line):
            names.append(line)
    return names


def col_description(name: str) -> str:
    if name in COL_DESC:
        return COL_DESC[name]
    return name.replace("_", " ").capitalize() + "."


def build_tests(model: str, col: str, meta: dict) -> list:
    tests: list = []
    if col == meta.get("pk"):
        tests.extend([{"unique": {}}, {"not_null": {}}])
    if col in meta.get("fks", {}):
        ref_model = meta["fks"][col]
        rel = {
            "relationships": {
                "to": f"ref('{ref_model}')",
                "field": FK_FIELD[ref_model],
            }
        }
        if (model, col) in WARN_RELATIONSHIPS:
            rel["relationships"]["config"] = {"severity": "warn"}
        tests.append(rel)
    if col in meta.get("accepted", {}):
        av = {"accepted_values": {"values": meta["accepted"][col]}}
        if col in meta.get("accepted_where", {}):
            av["accepted_values"]["config"] = {"where": meta["accepted_where"][col]}
        tests.append(av)
    return tests


def build_group(prefix: str, out_rel: str) -> None:
    models = []
    for sql in sorted((ROOT / "models" / "staging").rglob(f"{prefix}*.sql")):
        name = sql.stem
        meta = META[name]
        columns = []
        for col in cols_from_sql(sql):
            entry = {"name": col, "description": col_description(col)}
            tests = build_tests(name, col, meta)
            if tests:
                entry["data_tests"] = tests
            columns.append(entry)
        models.append(
            {"name": name, "description": meta["desc"], "columns": columns}
        )

    out = ROOT / out_rel
    out.write_text(
        yaml.dump({"version": 2, "models": models}, sort_keys=False),
        encoding="utf-8",
    )
    print(f"Wrote {out} ({len(models)} models)")


if __name__ == "__main__":
    build_group("stg_crm__", "models/staging/crm/_stg_crm__models.yml")
    build_group("stg_payments__", "models/staging/payments/_stg_payments__models.yml")
