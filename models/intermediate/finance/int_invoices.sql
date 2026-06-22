with invoices as (

    select * from {{ ref('stg_crm__aos_invoices') }}

),

customers as (

    select * from {{ ref('int_customers') }}

),

enriched as (

    select
        invoices.invoice_id,
        invoices.invoice_name,
        invoices.created_at,
        invoices.updated_at,
        invoices.invoice_status,
        invoices.invoice_amount_sar,
        invoices.vat_amount_sar,
        invoices.amount_ex_vat_sar,
        invoices.zoho_invoice_number,
        invoices.billing_account_id,
        invoices.customer_id,
        invoices.channel_partner_id,
        invoices.program_id,
        invoices.invoice_date,
        invoices.invoice_due_date,
        invoices.settlement_date,
        invoices.is_paid,
        customers.customer_name,
        customers.corporate_company_id,
        customers.corporate_company_name,
        customers.zoho_customer_id,
        (customers.customer_id is not null) as has_valid_customer

    from invoices
    left join customers
        on invoices.customer_id = customers.customer_id

)

select * from enriched
