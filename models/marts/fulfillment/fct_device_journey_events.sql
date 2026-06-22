with journey_events as (

    select * from {{ ref('stg_crm__tos_devices_journey') }}

),

devices as (

    select * from {{ ref('int_devices') }}

),

enriched as (

    select
        journey_events.device_journey_id,
        journey_events.device_id,
        devices.order_item_id,
        devices.order_id,
        devices.customer_id,
        devices.subscription_id,
        devices.program_id,
        devices.channel_partner_id,
        journey_events.movement_date,
        journey_events.device_movement,
        journey_events.created_at as event_recorded_at,
        (devices.device_id is not null) as has_valid_device

    from journey_events
    left join devices
        on journey_events.device_id = devices.device_id

)

select * from enriched
