with master_skus as (

    select * from {{ ref('stg_crm__tos_master_skus') }}

),

order_item_rollups as (

    select
        master_sku_id,
        count(*) as order_item_count,
        sum(quantity) as units_ordered,
        sum(total_price_vat_inclusive) as order_item_revenue_sar

    from {{ ref('int_order_items') }}
    where master_sku_id is not null
    group by 1

),

enriched as (

    select
        master_skus.master_sku_id,
        master_skus.master_sku_name,
        master_skus.created_at,
        master_skus.updated_at,
        master_skus.brand,
        master_skus.model,
        master_skus.memory,
        master_skus.color,
        master_skus.category,
        master_skus.sku_master_uid,
        master_skus.device_sku_key,
        coalesce(order_item_rollups.order_item_count, 0) as order_item_count,
        coalesce(order_item_rollups.units_ordered, 0) as units_ordered,
        coalesce(order_item_rollups.order_item_revenue_sar, 0) as order_item_revenue_sar,
        case
            when coalesce(order_item_rollups.order_item_count, 0) > 0
                then 'sold'
            else 'not_sold'
        end as sku_sales_segment

    from master_skus
    left join order_item_rollups
        on master_skus.master_sku_id = order_item_rollups.master_sku_id

)

select * from enriched
