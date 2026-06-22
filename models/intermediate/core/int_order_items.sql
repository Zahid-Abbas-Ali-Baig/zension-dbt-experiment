with order_items as (

    select * from {{ ref('stg_crm__tos_order_items') }}

),

orders as (

    select * from {{ ref('int_orders') }}

),

device_skus as (

    select * from {{ ref('int_device_skus') }}

),

cp_skus as (

    select * from {{ ref('stg_crm__tos_cp_skus') }}

),

cp_master_skus as (

    select * from {{ ref('stg_crm__tos_master_skus') }}

),

resolved_skus as (

    select
        order_items.order_item_id,
        order_items.order_item_name,
        order_items.created_at,
        order_items.updated_at,
        order_items.order_id,
        order_items.zaam_sku_id,
        order_items.cp_sku_id,
        order_items.customer_id,
        order_items.quantity,
        order_items.unit_price_vat_inclusive,
        order_items.total_price_vat_inclusive,
        order_items.device_purchase_price_vat_inclusive,
        order_items.discount_amount,
        order_items.product_type,
        order_items.order_line_item_type,
        order_items.imei_1,
        order_items.serial_no,
        coalesce(order_items.zaam_sku_id, cp_skus.zaam_sku_id) as resolved_zaam_sku_id,
        coalesce(
            zaam_device_skus.brand,
            cp_zaam_device_skus.brand,
            cp_master_skus.brand
        ) as brand,
        coalesce(
            zaam_device_skus.model,
            cp_zaam_device_skus.model,
            cp_master_skus.model
        ) as model,
        coalesce(
            zaam_device_skus.memory,
            cp_zaam_device_skus.memory,
            cp_master_skus.memory
        ) as memory,
        coalesce(
            zaam_device_skus.color,
            cp_zaam_device_skus.color,
            cp_master_skus.color
        ) as color,
        coalesce(
            zaam_device_skus.device_sku_key,
            cp_zaam_device_skus.device_sku_key,
            cp_master_skus.device_sku_key,
            'sku_unknown'
        ) as device_sku_key,
        coalesce(
            zaam_device_skus.master_sku_id,
            cp_zaam_device_skus.master_sku_id,
            cp_skus.master_sku_id,
            cp_master_skus.master_sku_id
        ) as master_sku_id,
        (orders.order_id is not null) as has_valid_order,
        (
            order_items.zaam_sku_id is not null
            and zaam_device_skus.zaam_sku_id is not null
        ) as has_valid_zaam_sku,
        (
            order_items.cp_sku_id is not null
            and cp_skus.cp_sku_id is not null
        ) as has_valid_cp_sku,
        (
            coalesce(order_items.zaam_sku_id, cp_skus.zaam_sku_id) is not null
            and coalesce(zaam_device_skus.zaam_sku_id, cp_skus.zaam_sku_id) is not null
        ) as has_valid_resolved_sku

    from order_items
    left join orders
        on order_items.order_id = orders.order_id
    left join device_skus as zaam_device_skus
        on order_items.zaam_sku_id = zaam_device_skus.zaam_sku_id
    left join cp_skus
        on order_items.cp_sku_id = cp_skus.cp_sku_id
    left join device_skus as cp_zaam_device_skus
        on cp_skus.zaam_sku_id = cp_zaam_device_skus.zaam_sku_id
    left join cp_master_skus
        on cp_skus.master_sku_id = cp_master_skus.master_sku_id

),

enriched as (

    select
        resolved_skus.*,
        orders.program_id,
        orders.channel_partner_id,
        orders.partner_name,
        orders.program_name,
        orders.order_status,
        orders.is_gmv_eligible,
        orders.has_valid_customer

    from resolved_skus
    left join orders
        on resolved_skus.order_id = orders.order_id

)

select * from enriched
