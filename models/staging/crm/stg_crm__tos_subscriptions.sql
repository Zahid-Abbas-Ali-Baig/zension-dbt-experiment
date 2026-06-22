with source as (

    select * from {{ source('source', 'crm_tos_subscriptions') }}
    where deleted = false

),

renamed as (

    select
        id as subscription_id,
        trim(name) as subscription_name,
        date_entered as created_at,
        date_modified as updated_at,
        case
            when trim(subscription_status) = 'Waiting_For_Delivery'
                then 'waiting_for_delivery'
            else lower(trim(subscription_status))
        end as subscription_status,
        service_start_date as service_started_at,
        service_end_date as service_ended_at,
        subscription_close_date,
        nullif(trim(subscription_pricing_id), '') as subscription_pricing_id,
        nullif(trim(channel_partner_id), '') as channel_partner_id,
        nullif(trim(customer_id), '') as customer_id,
        nullif(trim(order_id), '') as order_id,
        nullif(trim(order_item_id), '') as order_item_id,
        trim(subscription_uid) as subscription_uid,
        lower(trim(product_type)) as product_type,
        nullif(trim(upgraded_subscription_id), '') as upgraded_subscription_id,
        (
            lower(trim(subscription_status)) = 'active'
            and service_start_date is not null
        ) as is_active_subscription,
        (
            lower(trim(subscription_status)) = 'active'
            and service_start_date is not null
        ) as is_mrr_eligible,
        (lower(trim(subscription_status)) = 'cancelled') as is_churned,
        (lower(trim(subscription_status)) = 'upgraded') as is_upgraded,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
