with source as (

    select * from {{ source('source', 'crm_aos_invoices') }}
    where deleted = false

),

renamed as (

    select
        id as invoice_id,
        trim(name) as invoice_name,
        date_entered as created_at,
        date_modified as updated_at,
        lower(trim(invoice_status)) as invoice_status,
        total_amount::numeric as invoice_amount_sar,
        vat_amount::numeric as vat_amount_sar,
        amount_ex_vat::numeric as amount_ex_vat_sar,
        trim(zoho_invoice_number) as zoho_invoice_number,
        nullif(trim(billing_account_id), '') as billing_account_id,
        nullif(trim(customer_id), '') as customer_id,
        nullif(trim(channel_partner_id), '') as channel_partner_id,
        nullif(trim(programs_id), '') as program_id,
        invoice_date,
        invoice_due_date,
        settlement_date,
        (lower(trim(invoice_status)) = 'paid') as is_paid,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
