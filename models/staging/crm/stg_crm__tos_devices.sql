with source as (

    select * from {{ source('source', 'crm_tos_devices') }}
    where deleted = false

),

renamed as (

    select
        id as device_id,
        trim(name) as device_name,
        date_entered as created_at,
        date_modified as updated_at,
        trim(serial_number) as serial_number,
        purchase_price::numeric as purchase_price,
        purchase_date,
        delivery_date,
        trim(brand) as brand,
        trim(model) as model,
        trim(device_memory) as device_memory,
        trim(color) as color,
        nullif(trim(order_item_id), '') as order_item_id,
        nullif(trim(zaam_sku_id), '') as zaam_sku_id,
        trim(imei1) as imei1,
        trim(imei2) as imei2,
        lower(trim(devices_type)) as device_type,
        lower(trim(device_condition)) as device_condition,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
