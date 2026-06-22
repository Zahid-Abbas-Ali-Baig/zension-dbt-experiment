with programs as (

    select * from {{ ref('stg_crm__tos_programs') }}

),

channel_partners as (

    select * from {{ ref('int_channel_partners') }}

),

subscriptions as (

    select * from {{ ref('stg_crm__tos_subscriptions') }}

),

subscription_counts as (

    select
        orders.program_id,
        count(*) filter (
            where subscriptions.subscription_status = 'active'
        ) as active_subscription_count,
        count(*) filter (
            where subscriptions.subscription_status = 'waiting_for_delivery'
        ) as waiting_for_delivery_subscription_count,
        count(*) filter (
            where subscriptions.subscription_status in ('active', 'waiting_for_delivery')
        ) as utilization_subscription_count

    from subscriptions
    inner join {{ ref('stg_crm__tos_orders') }} as orders
        on subscriptions.order_id = orders.order_id
    group by 1

),

enriched as (

    select
        programs.program_id,
        programs.program_name,
        programs.created_at,
        programs.updated_at,
        programs.program_status,
        programs.channel_partner_id,
        programs.program_uid,
        programs.subscription_limit,
        programs.payment_methods_limit,
        programs.program_start_date,
        programs.program_end_date,
        programs.is_fnf_program,
        channel_partners.partner_name,
        channel_partners.partner_type,
        coalesce(subscription_counts.active_subscription_count, 0) as active_subscription_count,
        coalesce(
            subscription_counts.waiting_for_delivery_subscription_count,
            0
        ) as waiting_for_delivery_subscription_count,
        coalesce(
            subscription_counts.utilization_subscription_count,
            0
        ) as utilization_subscription_count,
        case
            when programs.subscription_limit > 0
                then round(
                    coalesce(subscription_counts.utilization_subscription_count, 0)::numeric
                    / programs.subscription_limit::numeric,
                    4
                )
        end as program_subscription_utilization_pct,
        (
            programs.subscription_limit > 0
            and coalesce(subscription_counts.utilization_subscription_count, 0)
                > programs.subscription_limit
        ) as is_over_subscription_limit,
        (programs.program_status != 'active') as is_disabled_program,
        (channel_partners.channel_partner_id is not null) as has_valid_channel_partner

    from programs
    left join channel_partners
        on programs.channel_partner_id = channel_partners.channel_partner_id
    left join subscription_counts
        on programs.program_id = subscription_counts.program_id

)

select * from enriched
