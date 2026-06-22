with source as (

    select * from {{ source('source', 'crm_tos_master_skus') }}
    where deleted = false

),

renamed as (

    select
        id as master_sku_id,
        trim(name) as master_sku_name,
        date_entered as created_at,
        date_modified as updated_at,
        trim(brand) as brand,
        trim(model) as model,
        trim(memory) as memory,
        trim(color) as color,
        lower(trim(category)) as category,
        trim(sku_master_uid) as sku_master_uid,
        concat_ws(
            '|',
            trim(brand),
            trim(model),
            trim(memory),
            trim(color)
        ) as device_sku_key,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
