with devices as (

    select * from {{ ref('int_devices') }}

)

select
    devices.device_id,
    devices.order_item_id,
    devices.order_id,
    devices.customer_id,
    devices.subscription_id,
    devices.program_id,
    devices.channel_partner_id,
    devices.zaam_sku_id,
    devices.purchase_date,
    devices.delivery_date,
    devices.brand,
    devices.model,
    devices.device_memory,
    devices.color,
    devices.device_type,
    devices.device_condition,
    devices.has_valid_order_item,
    devices.has_valid_subscription,
    devices.is_active_subscription,
    devices.purchase_price

from devices
