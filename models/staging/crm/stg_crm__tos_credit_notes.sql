with source as (

    select * from {{ source('source', 'crm_tos_credit_notes') }}
    where deleted = false

),

renamed as (

    select
        id as credit_note_id,
        trim(name) as credit_note_name,
        date_entered as created_at,
        date_modified as updated_at,
        trim(zoho_credit_note_id) as zoho_credit_note_id,
        lower(trim(zoho_status)) as zoho_status,
        trim(credit_note_zoho_url) as credit_note_zoho_url,
        nullif(trim(invoice_id), '') as invoice_id,
        nullif(trim(credit_id), '') as credit_id,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
