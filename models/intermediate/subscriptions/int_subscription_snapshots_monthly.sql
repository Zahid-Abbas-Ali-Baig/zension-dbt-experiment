with subscriptions as (

    select * from {{ ref('int_subscriptions') }}

),

subscription_months as (

    select
        subscriptions.subscription_id,
        generate_series(
            date_trunc('month', coalesce(subscriptions.service_started_at, subscriptions.created_at))::date,
            date_trunc(
                'month',
                coalesce(
                    subscriptions.service_ended_at,
                    subscriptions.subscription_close_date,
                    current_date
                )
            )::date,
            interval '1 month'
        )::date as snapshot_month

    from subscriptions

),

enriched as (

    select
        subscription_months.subscription_id,
        subscription_months.snapshot_month,
        date_trunc('quarter', subscription_months.snapshot_month)::date as snapshot_quarter,
        subscriptions.subscription_status,
        subscriptions.service_started_at,
        subscriptions.service_ended_at,
        subscriptions.subscription_close_date,
        subscriptions.channel_partner_id,
        subscriptions.program_id,
        subscriptions.partner_name,
        subscriptions.monthly_subscription_amount_sar,
        subscriptions.is_mrr_eligible,
        subscriptions.is_churned,
        subscriptions.is_upgraded,
        subscriptions.is_kifed,
        (
            subscriptions.subscription_status = 'active'
            and subscriptions.service_started_at is not null
            and date_trunc('month', subscriptions.service_started_at)::date
                <= subscription_months.snapshot_month
            and (
                subscriptions.service_ended_at is null
                or date_trunc('month', subscriptions.service_ended_at)::date
                    > subscription_months.snapshot_month
            )
            and (
                subscriptions.subscription_close_date is null
                or date_trunc('month', subscriptions.subscription_close_date)::date
                    > subscription_months.snapshot_month
            )
        ) as is_active_at_month_end,
        (
            extract(month from subscription_months.snapshot_month)::int in (1, 4, 7, 10)
            and subscriptions.subscription_status = 'active'
            and subscriptions.service_started_at is not null
            and subscriptions.service_started_at::date <= subscription_months.snapshot_month
            and (
                subscriptions.service_ended_at is null
                or subscriptions.service_ended_at::date > subscription_months.snapshot_month
            )
            and (
                subscriptions.subscription_close_date is null
                or subscriptions.subscription_close_date::date > subscription_months.snapshot_month
            )
        ) as is_active_at_quarter_start,
        (
            subscriptions.is_churned
            and subscriptions.service_ended_at is not null
            and date_trunc('month', subscriptions.service_ended_at)::date
                = subscription_months.snapshot_month
        ) as is_churned_in_month,
        (
            subscriptions.is_upgraded
            and subscriptions.updated_at is not null
            and date_trunc('month', subscriptions.updated_at)::date
                = subscription_months.snapshot_month
        ) as is_upgraded_in_month,
        (
            subscriptions.is_kifed
            and subscriptions.updated_at is not null
            and date_trunc('month', subscriptions.updated_at)::date
                = subscription_months.snapshot_month
        ) as is_kifed_in_month

    from subscription_months
    inner join subscriptions
        on subscription_months.subscription_id = subscriptions.subscription_id

)

select * from enriched
