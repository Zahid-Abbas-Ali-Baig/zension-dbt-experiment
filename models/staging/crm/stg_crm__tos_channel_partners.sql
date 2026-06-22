with source as (

    select * from {{ source('source', 'crm_tos_channel_partners') }}
    where deleted = false

),

renamed as (

    select
        id as channel_partner_id,
        trim(name) as partner_name,
        date_entered as created_at,
        date_modified as updated_at,
        trim(legal_name) as legal_name,
        lower(trim(channel_partner_type)) as partner_type,
        trim(vat_trn_number) as vat_trn_number,
        trim(channel_partner_uid) as channel_partner_uid,
        lower(trim(status)) as partner_status,
        nullif(trim(country_id), '') as country_id,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
