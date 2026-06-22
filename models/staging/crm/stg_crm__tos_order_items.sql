with source as (

    select * from {{ source('source', 'crm_tos_order_items') }}
    where deleted = false

),

renamed as (

    select
        id as order_item_id,
        trim(name) as order_item_name,
        date_entered as created_at,
        date_modified as updated_at,
        nullif(trim(order_id), '') as order_id,
        nullif(trim(zaam_sku_id), '') as zaam_sku_id,
        nullif(trim(cp_sku_id), '') as cp_sku_id,
        nullif(trim(customer_id), '') as customer_id,
        quantity::numeric as quantity,
        unit_price_vat_inclusive::numeric as unit_price_vat_inclusive,
        total_price_vat_inclusive::numeric as total_price_vat_inclusive,
        device_purchase_price_vat_inclusive::numeric as device_purchase_price_vat_inclusive,
        discount_amount::numeric as discount_amount,
        lower(trim(product_type)) as product_type,
        lower(trim(order_line_item_type)) as order_line_item_type,
        trim(imei_1) as imei_1,
        trim(serial_no) as serial_no,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
