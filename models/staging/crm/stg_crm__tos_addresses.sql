with source as (

    select * from {{ source('source', 'crm_tos_addresses') }}
    where deleted = false

),

renamed as (

    select
        id as address_id,
        trim(name) as address_name,
        date_entered as created_at,
        date_modified as updated_at,
        nullif(trim(customer_id), '') as customer_id,
        lower(trim(addresses_type)) as address_type,
        trim(addresses_city) as city,
        trim(addresses_area) as area,
        trim(addresses_country) as country,
        trim(addresses_street) as street,
        trim(district) as district,
        trim(postal_code) as postal_code,
        addresses_default_address as is_default_address,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
