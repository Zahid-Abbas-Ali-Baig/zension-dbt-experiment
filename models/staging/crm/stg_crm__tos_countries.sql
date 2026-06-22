with source as (

    select * from {{ source('source', 'crm_tos_countries') }}
    where deleted = false

),

renamed as (

    select
        id as country_id,
        trim(name) as country_name,
        date_entered as created_at,
        date_modified as updated_at,
        trim(country_code) as country_code,
        trim(country_currency) as country_currency,
        vat_rate::numeric as vat_rate,
        trim(zoho_tax_id) as zoho_tax_id,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
