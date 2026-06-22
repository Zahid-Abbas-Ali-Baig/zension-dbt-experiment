with pricing as (

    select * from {{ ref('stg_crm__tos_subscription_pricing') }}

),

active_subscriptions as (

    select
        subscription_pricing_id,
        count(*) filter (where is_mrr_eligible) as mrr_eligible_subscription_count,
        sum(monthly_subscription_amount_sar) filter (where is_mrr_eligible) as total_mrr_sar

    from {{ ref('int_subscriptions') }}
    where subscription_pricing_id is not null
    group by 1

),

enriched as (

    select
        pricing.subscription_pricing_id,
        pricing.subscription_pricing_name,
        pricing.created_at,
        pricing.updated_at,
        pricing.monthly_subscription_amount_sar,
        pricing.zaam_sku_id,
        pricing.subscription_duration_id,
        pricing.subscription_pricing_status,
        pricing.subscription_pricing_start_date,
        pricing.subscription_pricing_end_date,
        coalesce(active_subscriptions.mrr_eligible_subscription_count, 0) as mrr_eligible_subscription_count,
        coalesce(active_subscriptions.total_mrr_sar, 0) as total_mrr_sar,
        case
            when coalesce(active_subscriptions.mrr_eligible_subscription_count, 0) > 0
                then 'active_pricing'
            when pricing.subscription_pricing_status = 'active'
                then 'active_unused'
            else 'inactive'
        end as pricing_utilization_segment

    from pricing
    left join active_subscriptions
        on pricing.subscription_pricing_id = active_subscriptions.subscription_pricing_id

)

select * from enriched
