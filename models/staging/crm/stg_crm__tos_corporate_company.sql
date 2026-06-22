with source as (

    select * from {{ source('source', 'crm_tos_corporate_company') }}
    where deleted = false

),

renamed as (

    select
        id as corporate_company_id,
        trim(name) as company_name,
        date_entered as created_at,
        date_modified as updated_at,
        trim(allowed_email_domains) as allowed_email_domains,
        lower(trim(status)) as company_status,
        nullif(trim(tos_channel_partners_id), '') as channel_partner_id,
        lower(trim(tos_corporate_company_type)) as company_type,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
