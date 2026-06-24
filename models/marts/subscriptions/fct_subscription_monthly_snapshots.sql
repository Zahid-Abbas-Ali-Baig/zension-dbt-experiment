with snapshots as (

    select * from {{ ref('int_subscription_snapshots_monthly') }}

)

select
    snapshots.subscription_id,
    snapshots.snapshot_month,
    snapshots.snapshot_quarter,
    snapshots.channel_partner_id,
    snapshots.program_id,
    snapshots.subscription_status,
    snapshots.service_started_at,
    snapshots.service_ended_at,
    snapshots.subscription_close_date,
    snapshots.monthly_subscription_amount_sar,
    snapshots.is_mrr_eligible,
    snapshots.is_active_at_month_end as is_active,
    snapshots.is_active_at_quarter_start,
    snapshots.is_churned_in_month as is_churned,
    snapshots.is_upgraded_in_month as is_upgraded,
    snapshots.is_kifed_in_month as is_kifed

from snapshots
