with invoice_line_items as (

    select * from {{ ref('stg_crm__tos_invoice_line_items') }}

),

subscriptions as (

    select * from {{ ref('int_subscriptions') }}

),

invoices as (

    select * from {{ ref('int_invoices') }}

),

enriched as (

    select
        invoice_line_items.invoice_line_item_id,
        invoice_line_items.invoice_line_item_name,
        invoice_line_items.created_at,
        invoice_line_items.updated_at,
        invoice_line_items.parent_invoice_line_item_id as invoice_id,
        invoice_line_items.subscription_id,
        invoice_line_items.order_item_id,
        invoice_line_items.line_item_id,
        invoice_line_items.line_amount_sar,
        invoice_line_items.line_amount_ex_vat_sar,
        invoice_line_items.vat_amount_sar,
        invoice_line_items.line_amount_incl_vat_sar,
        invoice_line_items.quantity,
        invoice_line_items.product_type,
        subscriptions.subscription_status,
        subscriptions.program_id,
        subscriptions.channel_partner_id,
        subscriptions.partner_name,
        subscriptions.monthly_subscription_amount_sar,
        invoices.invoice_status,
        invoices.invoice_date,
        invoices.zoho_invoice_number,
        invoices.customer_id,
        invoices.is_paid,
        (invoices.invoice_id is not null) as has_valid_invoice,
        (subscriptions.subscription_id is not null) as has_valid_subscription

    from invoice_line_items
    left join subscriptions
        on invoice_line_items.subscription_id = subscriptions.subscription_id
    left join invoices
        on invoice_line_items.parent_invoice_line_item_id = invoices.invoice_id

)

select * from enriched
