with credit_notes as (

    select * from {{ ref('stg_crm__tos_credit_notes') }}

),

invoices as (

    select * from {{ ref('int_invoices') }}

),

enriched as (

    select
        credit_notes.credit_note_id,
        credit_notes.credit_note_name,
        credit_notes.created_at,
        credit_notes.updated_at,
        credit_notes.zoho_credit_note_id,
        credit_notes.zoho_status,
        credit_notes.credit_note_zoho_url,
        credit_notes.invoice_id,
        credit_notes.credit_id,
        invoices.invoice_name,
        invoices.invoice_amount_sar,
        invoices.invoice_status,
        invoices.zoho_invoice_number,
        invoices.customer_id,
        invoices.customer_name,
        invoices.channel_partner_id,
        invoices.program_id,
        (invoices.invoice_id is not null) as has_valid_invoice

    from credit_notes
    left join invoices
        on credit_notes.invoice_id = invoices.invoice_id

)

select * from enriched
