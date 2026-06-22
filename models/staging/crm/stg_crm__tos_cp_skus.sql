with source as (

    select * from {{ source('source', 'crm_tos_cp_skus') }}
    where deleted = false

),

renamed as (

    select
        id as cp_sku_id,
        trim(name) as cp_sku_name,
        date_entered as created_at,
        date_modified as updated_at,
        nullif(trim(channel_partner_id), '') as channel_partner_id,
        nullif(trim(zaam_sku_id), '') as zaam_sku_id,
        nullif(trim(master_sku_id), '') as master_sku_id,
        purchase_price::numeric as purchase_price,
        lower(trim(category)) as category,
        trim(cp_item_code) as cp_item_code,
        trim(cp_skus_uid) as cp_sku_uid,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
