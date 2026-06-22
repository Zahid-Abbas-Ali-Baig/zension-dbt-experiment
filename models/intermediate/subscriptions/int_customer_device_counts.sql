with devices as (

    select * from {{ ref('int_devices') }}

),

summary as (

    select
        devices.customer_id,
        count(*) as device_count,
        count(distinct devices.order_id) as order_count_with_devices,
        min(devices.purchase_date) as first_device_purchase_date,
        max(devices.delivery_date) as latest_device_delivery_date

    from devices
    where devices.customer_id is not null
    group by 1

)

select * from summary
