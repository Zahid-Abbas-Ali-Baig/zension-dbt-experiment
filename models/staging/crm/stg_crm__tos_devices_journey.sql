with source as (

    select * from {{ source('source', 'crm_tos_devices_journey') }}
    where deleted = false

),

renamed as (

    select
        id as device_journey_id,
        trim(name) as device_journey_name,
        date_entered as created_at,
        date_modified as updated_at,
        lower(trim(device_movement)) as device_movement,
        movement_date,
        nullif(trim(devices_tos_devices_journey_id), '') as device_id,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
