with credit_notes as (

    select * from {{ ref('int_credit_notes') }}

)

select
    credit_notes.credit_note_id,
    credit_notes.invoice_id,
    credit_notes.customer_id,
    credit_notes.channel_partner_id,
    credit_notes.program_id,
    credit_notes.created_at::date as credit_note_date,
    credit_notes.zoho_credit_note_id,
    credit_notes.zoho_status,
    credit_notes.credit_note_zoho_url,
    credit_notes.has_valid_invoice,
    credit_notes.invoice_amount_sar as related_invoice_amount_sar,
    credit_notes.invoice_amount_sar as credit_value_sar

from credit_notes
