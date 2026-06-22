with devices as (

    select * from {{ ref('stg_crm__tos_devices') }}

),

order_items as (

    select * from {{ ref('int_order_items') }}

),

subscriptions as (

    select * from {{ ref('int_subscriptions') }}

),

enriched as (

    select
        devices.device_id,
        devices.device_name,
        devices.created_at,
        devices.updated_at,
        devices.serial_number,
        devices.purchase_price,
        devices.purchase_date,
        devices.delivery_date,
        devices.brand,
        devices.model,
        devices.device_memory,
        devices.color,
        devices.order_item_id,
        devices.zaam_sku_id,
        devices.imei1,
        devices.imei2,
        devices.device_type,
        devices.device_condition,
        order_items.order_id,
        order_items.program_id,
        order_items.channel_partner_id,
        order_items.partner_name,
        order_items.device_sku_key,
        order_items.customer_id,
        subscriptions.subscription_id,
        subscriptions.subscription_status,
        subscriptions.is_active_subscription,
        (order_items.order_item_id is not null) as has_valid_order_item,
        (subscriptions.subscription_id is not null) as has_valid_subscription

    from devices
    left join order_items
        on devices.order_item_id = order_items.order_item_id
    left join subscriptions
        on order_items.order_item_id = subscriptions.order_item_id

)

select * from enriched
