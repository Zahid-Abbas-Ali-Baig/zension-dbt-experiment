with zaam_skus as (

    select * from {{ ref('stg_crm__tos_zaam_skus') }}

),

master_skus as (

    select * from {{ ref('stg_crm__tos_master_skus') }}

),

enriched as (

    select
        zaam_skus.zaam_sku_id,
        zaam_skus.zaam_sku_name,
        zaam_skus.created_at,
        zaam_skus.updated_at,
        zaam_skus.master_sku_id,
        zaam_skus.barcode,
        zaam_skus.launch_rrp,
        zaam_skus.zaam_sku_type,
        zaam_skus.category as zaam_category,
        zaam_skus.zaam_sku_uid,
        master_skus.master_sku_name,
        master_skus.brand,
        master_skus.model,
        master_skus.memory,
        master_skus.color,
        master_skus.category as master_category,
        master_skus.device_sku_key,
        coalesce(
            master_skus.device_sku_key,
            'sku_unknown'
        ) as resolved_device_sku_key,
        (master_skus.master_sku_id is not null) as has_valid_master_sku

    from zaam_skus
    left join master_skus
        on zaam_skus.master_sku_id = master_skus.master_sku_id

)

select * from enriched
