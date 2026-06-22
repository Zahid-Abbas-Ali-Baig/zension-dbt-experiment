with invoice_line_items as (

    select * from {{ ref('int_invoice_line_items') }}

)

select
    invoice_line_items.invoice_line_item_id,
    invoice_line_items.invoice_id,
    invoice_line_items.subscription_id,
    invoice_line_items.order_item_id,
    invoice_line_items.customer_id,
    invoice_line_items.invoice_date,
    invoice_line_items.invoice_status,
    invoice_line_items.is_paid,
    invoice_line_items.has_valid_invoice,
    invoice_line_items.has_valid_subscription,
    invoice_line_items.quantity,
    invoice_line_items.product_type,
    invoice_line_items.line_amount_sar,
    invoice_line_items.line_amount_ex_vat_sar,
    invoice_line_items.vat_amount_sar,
    invoice_line_items.line_amount_incl_vat_sar

from invoice_line_items
