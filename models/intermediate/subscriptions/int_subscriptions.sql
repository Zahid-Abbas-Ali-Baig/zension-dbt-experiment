with subscriptions as (

    select * from {{ ref('stg_crm__tos_subscriptions') }}

),

pricing as (

    select * from {{ ref('stg_crm__tos_subscription_pricing') }}

),

durations as (

    select * from {{ ref('stg_crm__tos_subscription_durations') }}

),

orders as (

    select * from {{ ref('int_orders') }}

),

enriched as (

    select
        subscriptions.subscription_id,
        subscriptions.subscription_name,
        subscriptions.created_at,
        subscriptions.updated_at,
        subscriptions.subscription_status,
        subscriptions.service_started_at,
        subscriptions.service_ended_at,
        subscriptions.subscription_close_date,
        subscriptions.subscription_pricing_id,
        subscriptions.channel_partner_id,
        subscriptions.customer_id,
        subscriptions.order_id,
        subscriptions.order_item_id,
        subscriptions.subscription_uid,
        subscriptions.product_type,
        subscriptions.upgraded_subscription_id,
        subscriptions.is_churned,
        subscriptions.is_upgraded,
        pricing.monthly_subscription_amount_sar,
        pricing.subscription_duration_id,
        durations.duration_months as subscription_term_months,
        orders.program_id,
        orders.program_name,
        orders.channel_partner_id as order_channel_partner_id,
        orders.partner_name,
        orders.is_fnf_program,
        (pricing.subscription_pricing_id is not null) as has_valid_subscription_pricing,
        subscriptions.is_active_subscription,
        (
            subscriptions.is_active_subscription
            and pricing.subscription_pricing_id is not null
            and pricing.monthly_subscription_amount_sar is not null
        ) as is_mrr_eligible,
        (orders.order_id is not null) as has_valid_order,
        (subscriptions.customer_id is not null and orders.has_valid_customer) as has_valid_customer

    from subscriptions
    left join pricing
        on subscriptions.subscription_pricing_id = pricing.subscription_pricing_id
    left join durations
        on pricing.subscription_duration_id = durations.subscription_duration_id
    left join orders
        on subscriptions.order_id = orders.order_id

)

select * from enriched
