"""Merge codegen batch outputs into enriched models/staging/source/_sources.yml."""
from __future__ import annotations

import re
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "target"
OUT = ROOT / "models" / "staging" / "source" / "_sources.yml"

TABLE_DESCRIPTIONS: dict[str, str] = {
    "crm_tos_orders": (
        "Commercial orders placed through Zaam channel partners. Each row is one order "
        "covering device purchase, subscription bundling, and checkout lifecycle from "
        "payment through delivery or cancellation."
    ),
    "crm_tos_order_items": (
        "Line items on commercial orders. Each row is one product line (device, subscription "
        "component, or add-on) with pricing, SKU references, and quantity."
    ),
    "crm_tos_subscriptions": (
        "Device subscription contracts tied to orders. Each row tracks subscription lifecycle "
        "from waiting for delivery through active recurring billing, upgrade, or cancellation."
    ),
    "crm_tos_devices": (
        "Physical device assets fulfilled to customers. Each row is one device with brand, model, "
        "serial/IMEI identifiers linked to an order line item."
    ),
    "crm_tos_payments": (
        "CRM payment records for order collections and refunds. Each row links an order to amounts "
        "collected and the external Payment Service payment identifier."
    ),
    "crm_tos_payment_history": (
        "Card capture and payment attempt events. Each row records one authorization or charge "
        "attempt including failure codes for retry analysis."
    ),
    "crm_aos_invoices": (
        "Zoho Books synced invoices from SuiteCRM. Each row is one invoice with VAT amounts and "
        "synced Zoho invoice identifiers for finance reconciliation."
    ),
    "crm_tos_invoice_line_items": (
        "Invoice line items linked to subscriptions. Each row is one billed line with amounts "
        "exclusive and inclusive of VAT."
    ),
    "crm_tos_credit_notes": (
        "Credit notes issued against invoices and synced to Zoho Books. Each row represents one "
        "refund or adjustment document for finance reporting."
    ),
    "crm_accounts": (
        "Customer accounts in SuiteCRM. Each row is one end customer with identity verification "
        "status, corporate employer link, and Zoho customer reference."
    ),
    "crm_tos_channel_partners": (
        "Channel partners selling through the Zension platform (e.g. Jarir, ZAAM, Axiom). "
        "Each row defines one partner organization and partner type."
    ),
    "crm_tos_programs": (
        "Commercial programs offered by channel partners (CEP, Jarir, FnF, Tradeling). Each row "
        "configures subscription limits, status, and program rules."
    ),
    "crm_tos_corporate_company": (
        "Corporate employer entities for CEP employee programs. Each row is one company with "
        "allowed email domains for employee eligibility."
    ),
    "crm_tos_master_skus": (
        "Master device SKU catalog with brand, model, memory, and color attributes. Each row is "
        "one canonical hardware SKU for sales analytics."
    ),
    "crm_tos_zaam_skus": (
        "Zaam program-specific SKUs mapped to master SKUs. Each row is one sellable SKU in a "
        "program catalog with pricing context."
    ),
    "crm_tos_cp_skus": (
        "Bridge mapping channel partners to Zaam SKUs. Each row links a partner catalog entry to "
        "a Zaam SKU for partner-specific device offerings."
    ),
    "crm_tos_subscription_pricing": (
        "Subscription price list entries with monthly recurring amounts used for MRR calculations."
    ),
    "crm_tos_subscription_durations": (
        "Subscription term options in months linked to programs and pricing records."
    ),
    "crm_tos_addresses": (
        "Customer and partner delivery addresses including region fields used for fulfillment SLA."
    ),
    "crm_tos_payment_methods": (
        "Stored payment methods on file in CRM including card expiry for outstanding payment "
        "monitoring."
    ),
    "crm_tos_countries": (
        "Country reference data including Zoho tax identifiers for KSA VAT configuration."
    ),
    "crm_tos_api_logs": (
        "Partner and API integration call log. Each row is one outbound API request with success "
        "or failure status for webhook reliability metrics."
    ),
    "crm_tos_devices_journey": (
        "Device fulfillment journey milestones. Each row captures a delivery or handover event "
        "supplementing order delivery timestamps."
    ),
    "payments_payments": (
        "Payment Service payment intents. Each row is one PSP payment linked to a subscriber and "
        "optional PSP subscription."
    ),
    "payments_transactions": (
        "Payment Service transaction outcomes. Each row records process and request status for "
        "card processing success, failure, and retry queue analysis."
    ),
    "payments_refunds": (
        "Payment Service refund events. Each row is one refund amount and approval status."
    ),
    "payments_subscribers": (
        "Payment Service subscriber profiles. Each row is one payer identity with external "
        "Stripe identifier."
    ),
    "payments_subscriptions": (
        "Payment Service recurring billing subscriptions. Each row is one PSP subscription entity."
    ),
    "payments_payment_methods": (
        "Payment methods stored at the Payment Service including card-on-file details."
    ),
}

COLUMN_DESCRIPTIONS: dict[str, dict[str, str]] = {
    "crm_tos_orders": {
        "id": "Primary key for the order record in SuiteCRM.",
        "order_status": "Current lifecycle status of the order (e.g. delivered, cancelled).",
        "order_type": "Commercial order type distinguishing standard orders from pre-orders.",
        "total_tos_amount_incl_vat": "Total order amount including VAT in SAR used for GMV.",
        "customer_id": "Foreign key to the customer account that placed the order.",
        "programs_order_id": "Foreign key to the commercial program under which the order was placed.",
        "payment_method_id": "Foreign key to the CRM payment method used at checkout.",
        "delivered_on": "Date the order was delivered to the customer.",
        "sales_channel": "Sales channel identifier for partner attribution.",
        "deleted": "SuiteCRM soft-delete flag; exclude from analytics when true.",
    },
    "crm_tos_order_items": {
        "id": "Primary key for the order line item.",
        "order_id": "Foreign key to the parent commercial order.",
        "zaam_sku_id": "Foreign key to the Zaam program SKU when the line references catalog pricing.",
        "cp_sku_id": "Foreign key to the channel-partner SKU mapping when partner catalog is used.",
        "customer_id": "Foreign key to the customer account on the line item.",
        "quantity": "Number of units on the line.",
        "total_price_vat_inclusive": "Line total including VAT in SAR.",
    },
    "crm_tos_subscriptions": {
        "id": "Primary key for the subscription record.",
        "subscription_status": "Lifecycle status (Active, Waiting_For_Delivery, Cancelled, Upgraded).",
        "service_start_date": "Date recurring service began; required for active MRR eligibility.",
        "service_end_date": "Date recurring service ended if closed.",
        "order_id": "Foreign key to the originating commercial order.",
        "order_item_id": "Foreign key to the order line item that created this subscription.",
        "customer_id": "Foreign key to the subscribing customer account.",
        "channel_partner_id": "Foreign key to the channel partner selling the subscription.",
        "subscription_pricing_id": "Foreign key to the price list entry for monthly recurring amount.",
        "subscription_uid": "External subscription identifier used for PSP reconciliation.",
    },
    "crm_tos_devices": {
        "id": "Primary key for the device asset.",
        "order_item_id": "Foreign key to the order line item that fulfilled this device.",
        "brand": "Device manufacturer brand.",
        "model": "Device model name.",
        "device_memory": "Storage capacity of the device.",
        "color": "Device color variant.",
    },
    "crm_tos_payments": {
        "id": "Primary key for the CRM payment record.",
        "payment_status": "Collection status (paid, failed, refunded, etc.).",
        "order_id": "Foreign key to the order being paid.",
        "payment_id": "Foreign key to the Payment Service payment intent (text UUID).",
        "payment_amount_tax_inclusive": "Amount collected including tax in SAR.",
        "refund_amount": "Refund amount in SAR when payment was refunded.",
    },
    "crm_tos_payment_history": {
        "id": "Primary key for the payment attempt event.",
        "status": "Outcome of the card capture attempt (paid, failed, Approved, etc.).",
        "payment_id": "Foreign key to the parent CRM payment record.",
        "error_code": "Processor error code when the attempt failed.",
        "error_reason": "Human-readable failure reason from the payment processor.",
    },
    "crm_aos_invoices": {
        "id": "Primary key for the synced invoice.",
        "invoice_status": "Invoice collection status in Zoho (paid or unpaid).",
        "total_amount": "Invoice total amount in SAR.",
        "vat_amount": "VAT portion of the invoice in SAR.",
        "zoho_invoice_number": "Invoice number assigned in Zoho Books.",
        "billing_account_id": "Foreign key to the customer account billed on the invoice.",
    },
    "crm_tos_invoice_line_items": {
        "id": "Primary key for the invoice line.",
        "invoice_id": "Foreign key to the parent Zoho-synced invoice.",
        "tos_subscriptions_id": "Foreign key to the subscription billed on this line.",
    },
    "crm_tos_credit_notes": {
        "id": "Primary key for the credit note.",
        "zoho_credit_note_id": "Credit note identifier in Zoho Books.",
        "zoho_status": "Sync status of the credit note in Zoho.",
    },
    "crm_accounts": {
        "id": "Primary key for the customer account.",
        "national_id": "Saudi national ID used as primary customer identifier.",
        "nafath_verified": "Whether the customer passed Nafath identity verification.",
        "is_mobile_verified": "Mobile OTP verification flag stored as Yes/No text.",
        "corporate_company_id": "Foreign key to the CEP corporate employer when applicable.",
        "zoho_customer_id": "Customer identifier in Zoho Books for finance reconciliation.",
    },
    "crm_tos_channel_partners": {
        "id": "Primary key for the channel partner.",
        "name": "Display name of the channel partner (e.g. Jarir, Axiom).",
        "channel_partner_type": "Partner classification such as Retailer or ecommerce.",
    },
    "crm_tos_programs": {
        "id": "Primary key for the commercial program.",
        "name": "Program name (CEP, Jarir, FnF, Tradeling, etc.).",
        "program_status": "Whether the program is active and accepting orders.",
        "channel_partner_id": "Foreign key to the owning channel partner.",
        "subscription_limit": "Maximum allowed active subscriptions for the program.",
    },
    "crm_tos_corporate_company": {
        "id": "Primary key for the corporate employer entity.",
        "allowed_email_domains": "Comma-separated email domains eligible for CEP employee signup.",
    },
    "crm_tos_master_skus": {
        "id": "Primary key for the master device SKU.",
        "brand": "Device manufacturer brand.",
        "model": "Device model name.",
        "memory": "Storage capacity attribute.",
        "color": "Color variant attribute.",
    },
    "crm_tos_zaam_skus": {
        "id": "Primary key for the Zaam program SKU.",
        "tos_master_skus_id": "Foreign key to the canonical master SKU attributes.",
    },
    "crm_tos_cp_skus": {
        "id": "Primary key for the channel-partner SKU mapping.",
        "channel_partner_id": "Foreign key to the channel partner owning this catalog entry.",
        "zaam_sku_id": "Foreign key to the Zaam SKU being offered by the partner.",
    },
    "crm_tos_subscription_pricing": {
        "id": "Primary key for the subscription price list entry.",
        "monthly_subscription_amount": "Monthly recurring charge in SAR used for MRR.",
        "zaam_sku_id": "Foreign key to the Zaam SKU this price applies to.",
        "tos_subscription_durations_id": "Foreign key to the subscription term option in months.",
    },
    "crm_tos_subscription_durations": {
        "id": "Primary key for the subscription duration option.",
        "duration": "Subscription term length in months.",
        "tos_channel_partners_id": "Foreign key to the channel partner offering this term.",
    },
    "crm_tos_addresses": {
        "id": "Primary key for the address record.",
    },
    "crm_tos_payment_methods": {
        "id": "Primary key for the stored CRM payment method.",
    },
    "crm_tos_countries": {
        "id": "Primary key for the country reference row.",
        "zoho_tax_id": "Zoho Books tax identifier configured for this country.",
    },
    "crm_tos_api_logs": {
        "id": "Primary key for the API call log entry.",
        "status": "Outcome of the API call (success or failure).",
    },
    "crm_tos_devices_journey": {
        "id": "Primary key for the device journey milestone.",
    },
    "payments_payments": {
        "id": "Primary key for the PSP payment intent.",
        "subscriber_id": "Foreign key to the Payment Service subscriber.",
        "subscription_id": "Foreign key to the PSP recurring subscription when applicable.",
    },
    "payments_transactions": {
        "id": "Primary key for the PSP transaction.",
        "subscriber_id": "Foreign key to the subscriber who initiated the transaction.",
        "process_status": "Processing pipeline status (completed, queued, failed, in_progress).",
        "request_status": "Authorization or capture request outcome from the processor.",
    },
    "payments_refunds": {
        "id": "Primary key for the PSP refund.",
        "status": "Refund approval status from the payment processor.",
        "amount": "Refunded amount.",
    },
    "payments_subscribers": {
        "id": "Primary key for the PSP subscriber profile.",
        "stripe_id": "External Stripe customer identifier.",
    },
    "payments_subscriptions": {
        "id": "Primary key for the PSP subscription entity.",
    },
    "payments_payment_methods": {
        "id": "Primary key for the PSP stored payment method.",
    },
}

PK_COLUMNS = {"id"}

# FK target: (ref_table, ref_field, require_not_null)
FK_TESTS: dict[str, dict[str, tuple[str, str, bool]]] = {
    "crm_tos_orders": {
        "customer_id": ("crm_accounts", "id", False),
        "programs_order_id": ("crm_tos_programs", "id", True),
        "payment_method_id": ("crm_tos_payment_methods", "id", False),
    },
    "crm_tos_order_items": {
        "order_id": ("crm_tos_orders", "id", True),
        "zaam_sku_id": ("crm_tos_zaam_skus", "id", False),
        "customer_id": ("crm_accounts", "id", False),
    },
    "crm_tos_subscriptions": {
        "order_id": ("crm_tos_orders", "id", True),
        "order_item_id": ("crm_tos_order_items", "id", False),
        "customer_id": ("crm_accounts", "id", False),
        "channel_partner_id": ("crm_tos_channel_partners", "id", True),
        "subscription_pricing_id": ("crm_tos_subscription_pricing", "id", False),
    },
    "crm_tos_devices": {
        "order_item_id": ("crm_tos_order_items", "id", False),
    },
    "crm_tos_payments": {
        "order_id": ("crm_tos_orders", "id", True),
        "payment_id": ("payments_payments", "id", False),
    },
    "crm_tos_payment_history": {
        "payment_id": ("crm_tos_payments", "id", False),
    },
    "crm_aos_invoices": {
        "billing_account_id": ("crm_accounts", "id", False),
    },
    "crm_tos_invoice_line_items": {
        "invoice_id": ("crm_aos_invoices", "id", True),
        "tos_subscriptions_id": ("crm_tos_subscriptions", "id", False),
    },
    "crm_tos_programs": {
        "channel_partner_id": ("crm_tos_channel_partners", "id", True),
    },
    "crm_accounts": {
        "corporate_company_id": ("crm_tos_corporate_company", "id", False),
    },
    "crm_tos_zaam_skus": {
        "tos_master_skus_id": ("crm_tos_master_skus", "id", True),
    },
    "crm_tos_cp_skus": {
        "channel_partner_id": ("crm_tos_channel_partners", "id", True),
        "zaam_sku_id": ("crm_tos_zaam_skus", "id", False),
    },
    "crm_tos_subscription_pricing": {
        "zaam_sku_id": ("crm_tos_zaam_skus", "id", False),
        "tos_subscription_durations_id": ("crm_tos_subscription_durations", "id", False),
    },
    "crm_tos_subscription_durations": {
        "tos_channel_partners_id": ("crm_tos_channel_partners", "id", True),
    },
    "payments_payments": {
        "subscriber_id": ("payments_subscribers", "id", True),
        "subscription_id": ("payments_subscriptions", "id", False),
    },
    "payments_transactions": {
        "subscriber_id": ("payments_subscribers", "id", True),
    },
}

ACCEPTED_VALUES: dict[str, dict[str, list[str | None]]] = {
    "crm_tos_orders": {
        "order_status": [
            "cancelled",
            "delivered",
            "expired",
            "rejected",
            "waiting_for_delivery",
        ],
        "order_type": ["order", "pre-order"],
    },
    "crm_tos_subscriptions": {
        "subscription_status": ["Active", "Cancelled", "Upgraded", "Waiting_For_Delivery"],
    },
    "crm_tos_payments": {
        "payment_status": ["cancelled", "failed", "not_invoiced", "paid", "refunded"],
    },
    "crm_tos_payment_history": {
        "status": ["Approved", "failed", "paid", "Paid", "success"],
    },
    "crm_aos_invoices": {
        "invoice_status": ["paid", "unpaid"],
    },
    "crm_tos_api_logs": {
        "status": ["failure", "success"],
    },
    "crm_tos_programs": {
        "program_status": ["ACTIVE"],
    },
    "crm_tos_channel_partners": {
        "channel_partner_type": ["ecommerce", "Retailer"],
    },
    "payments_transactions": {
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
    "payments_refunds": {
        "status": ["Approved"],
    },
}

NULLABLE_ENUM_WHERE: dict[str, dict[str, str]] = {
    "crm_tos_orders": {"order_type": "order_type is not null"},
    "payments_transactions": {"request_status": "request_status is not null"},
}

BATCH_ORDER = [
    "codegen_batch4.yml",
    "codegen_batch1.yml",
    "codegen_batch2.yml",
    "codegen_batch6.yml",
    "codegen_batch5.yml",
    "codegen_batch3.yml",
    "codegen_batch7.yml",
    "codegen_batch8.yml",
    "codegen_batch9.yml",
    "codegen_batch10.yml",
]


def extract_yaml(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    match = re.search(r"^version:\s*2\s*$", text, re.MULTILINE)
    if not match:
        raise ValueError(f"No YAML block in {path}")
    return yaml.safe_load(text[match.start() :])


def humanize_column(name: str) -> str:
    return name.replace("_", " ").strip().capitalize() + "."


def build_column_tests(table: str, col: str) -> list:
    tests: list = []
    if col in PK_COLUMNS:
        tests.extend(["unique", "not_null"])
    fks = FK_TESTS.get(table, {})
    if col in fks:
        ref_table, ref_field, require_not_null = fks[col]
        if require_not_null:
            tests.append("not_null")
        tests.append(
            {
                "relationships": {
                    "to": f"source('source', '{ref_table}')",
                    "field": ref_field,
                }
            }
        )
    accepted = ACCEPTED_VALUES.get(table, {}).get(col)
    if accepted is not None:
        payload: dict = {"values": accepted}
        where = NULLABLE_ENUM_WHERE.get(table, {}).get(col)
        if where:
            payload["config"] = {"where": where}
        tests.append({"accepted_values": payload})
    return tests


def enrich_table(table: dict) -> dict:
    name = table["name"]
    col_docs = COLUMN_DESCRIPTIONS.get(name, {})
    enriched_columns = []
    for col in table.get("columns", []):
        col_name = col["name"]
        enriched = {
            "name": col_name,
            "data_type": col.get("data_type"),
            "description": col_docs.get(col_name) or humanize_column(col_name),
        }
        tests = build_column_tests(name, col_name)
        if tests:
            enriched["data_tests"] = tests
        enriched_columns.append(enriched)
    return {
        "name": name,
        "description": TABLE_DESCRIPTIONS[name],
        "columns": enriched_columns,
    }


def main() -> None:
    tables: list[dict] = []
    seen: set[str] = set()
    for batch_file in BATCH_ORDER:
        data = extract_yaml(TARGET / batch_file)
        for table in data["sources"][0]["tables"]:
            if table["name"] not in seen:
                tables.append(enrich_table(table))
                seen.add(table["name"])

    output = {
        "version": 2,
        "sources": [
            {
                "name": "source",
                "description": (
                    "Operational data replicated from SuiteCRM (tos-ksa) and the Payment Service "
                    "into the zension warehouse. Supports order, subscription, payment, and "
                    "finance analytics for KSA channel partner programs."
                ),
                "database": "zension",
                "schema": "source",
                "tables": tables,
            }
        ],
    }

    OUT.parent.mkdir(parents=True, exist_ok=True)
    header = (
        "# Source definitions for SuiteCRM and Payment Service tables.\n"
        "# Generated from codegen batches; status values profiled from warehouse.\n\n"
    )
    OUT.write_text(header + yaml.dump(output, sort_keys=False, default_flow_style=False), encoding="utf-8")
    print(f"Wrote {len(tables)} tables to {OUT}")


if __name__ == "__main__":
    main()
