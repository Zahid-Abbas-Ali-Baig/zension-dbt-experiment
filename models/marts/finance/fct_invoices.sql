with invoices as (

    select * from {{ ref('int_invoices') }}

)

select
    invoices.invoice_id,
    invoices.customer_id,
    invoices.channel_partner_id,
    invoices.program_id,
    invoices.billing_account_id,
    invoices.invoice_date,
    invoices.invoice_due_date,
    invoices.settlement_date,
    invoices.invoice_status,
    invoices.zoho_invoice_number,
    invoices.is_paid,
    invoices.has_valid_customer,
    invoices.invoice_amount_sar,
    invoices.vat_amount_sar,
    invoices.amount_ex_vat_sar

from invoices
