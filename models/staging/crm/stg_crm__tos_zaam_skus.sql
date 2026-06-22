with source as (

    select * from {{ source('source', 'crm_tos_zaam_skus') }}
    where deleted = false

),

renamed as (

    select
        id as zaam_sku_id,
        trim(name) as zaam_sku_name,
        date_entered as created_at,
        date_modified as updated_at,
        nullif(trim(tos_master_skus_id), '') as master_sku_id,
        trim(barcode) as barcode,
        launch_rrp::numeric as launch_rrp,
        lower(trim(zaam_skus_type)) as zaam_sku_type,
        lower(trim(category)) as category,
        trim(zaam_skus_uid) as zaam_sku_uid,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
