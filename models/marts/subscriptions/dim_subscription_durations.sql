with durations as (

    select * from {{ ref('stg_crm__tos_subscription_durations') }}

),

subscription_rollups as (

    select
        subscription_duration_id,
        count(*) as subscription_count,
        count(*) filter (where is_mrr_eligible) as mrr_eligible_subscription_count,
        avg(subscription_term_months) as avg_subscription_term_months

    from {{ ref('int_subscriptions') }}
    where subscription_duration_id is not null
    group by 1

),

enriched as (

    select
        durations.subscription_duration_id,
        durations.subscription_duration_name,
        durations.created_at,
        durations.updated_at,
        durations.duration_months,
        durations.duration_status,
        durations.program_id,
        durations.channel_partner_id,
        durations.duration_start_date,
        durations.duration_end_date,
        coalesce(subscription_rollups.subscription_count, 0) as subscription_count,
        coalesce(subscription_rollups.mrr_eligible_subscription_count, 0) as mrr_eligible_subscription_count,
        subscription_rollups.avg_subscription_term_months,
        case
            when coalesce(subscription_rollups.mrr_eligible_subscription_count, 0) > 0
                then 'in_use'
            when durations.duration_status = 'active'
                then 'available'
            else 'inactive'
        end as duration_utilization_segment

    from durations
    left join subscription_rollups
        on durations.subscription_duration_id = subscription_rollups.subscription_duration_id

)

select * from enriched
