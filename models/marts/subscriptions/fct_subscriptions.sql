with subscriptions as (

    select * from {{ ref('int_subscriptions') }}

)

select
    subscriptions.subscription_id,
    subscriptions.customer_id,
    subscriptions.order_id,
    subscriptions.order_item_id,
    subscriptions.channel_partner_id,
    subscriptions.program_id,
    subscriptions.subscription_pricing_id,
    subscriptions.created_at::date as subscription_date,
    subscriptions.subscription_status,
    subscriptions.service_started_at,
    subscriptions.service_ended_at,
    subscriptions.subscription_close_date,
    subscriptions.is_active_subscription,
    subscriptions.is_mrr_eligible,
    subscriptions.is_churned,
    subscriptions.is_upgraded,
    subscriptions.is_kifed,
    subscriptions.is_upgraded_or_kifed,
    subscriptions.has_valid_subscription_pricing,
    subscriptions.has_valid_order,
    subscriptions.has_valid_customer,
    subscriptions.monthly_subscription_amount_sar as monthly_recurring_amount_sar,
    subscriptions.subscription_term_months

from subscriptions
