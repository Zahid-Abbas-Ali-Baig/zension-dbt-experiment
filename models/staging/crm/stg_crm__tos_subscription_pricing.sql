with source as (

    select * from {{ source('source', 'crm_tos_subscription_pricing') }}
    where deleted = false

),

renamed as (

    select
        id as subscription_pricing_id,
        trim(name) as subscription_pricing_name,
        date_entered as created_at,
        date_modified as updated_at,
        monthly_subscription_amount::numeric as monthly_subscription_amount_sar,
        nullif(trim(zaam_sku_id), '') as zaam_sku_id,
        nullif(trim(tos_subscription_durations_id), '') as subscription_duration_id,
        lower(trim(subscription_pricing_status)) as subscription_pricing_status,
        subscription_pricing_start_date,
        subscription_pricing_end_date,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
