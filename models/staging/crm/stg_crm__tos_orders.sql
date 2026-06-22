with source as (

    select * from {{ source('source', 'crm_tos_orders') }}
    where deleted = false

),

renamed as (

    select
        id as order_id,
        trim(name) as order_number,
        date_entered as created_at,
        date_modified as updated_at,
        lower(trim(order_status)) as order_status,
        coalesce(lower(trim(order_type)), 'unknown') as order_type,
        total_tos_amount_incl_vat::numeric as gmv_amount_sar,
        nullif(trim(customer_id), '') as customer_id,
        nullif(trim(programs_order_id), '') as program_id,
        delivered_on as delivered_at,
        lower(trim(sales_channel)) as sales_channel,
        nullif(trim(payment_method_id), '') as payment_method_id,
        total_discount_amount::numeric as total_discount_amount,
        total_amount_incl_vat::numeric as total_amount_incl_vat,
        (lower(trim(order_type)) = 'pre-order') as is_preorder,
        (
            lower(trim(order_status)) in ('cancelled', 'rejected', 'expired')
        ) as is_voided,
        (
            lower(trim(order_status)) not in ('cancelled', 'rejected', 'expired')
        ) as is_gmv_eligible,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
