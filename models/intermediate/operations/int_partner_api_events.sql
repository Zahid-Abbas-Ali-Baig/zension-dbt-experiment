with api_logs as (

    select * from {{ ref('stg_crm__tos_api_logs') }}

),

orders as (

    select
        order_id,
        channel_partner_id
    from {{ ref('int_orders') }}

),

subscriptions as (

    select
        subscription_id,
        channel_partner_id
    from {{ ref('int_subscriptions') }}

),

customers as (

    select
        customer_id,
        channel_partner_id
    from {{ ref('int_customers') }}

),

partner_attribution as (

    select
        api_logs.api_log_id,
        coalesce(
            case
                when lower(trim(api_logs.parent_type)) = 'tos_channel_partners'
                    then api_logs.parent_id
            end,
            orders.channel_partner_id,
            subscriptions.channel_partner_id,
            customers.channel_partner_id
        ) as channel_partner_id

    from api_logs
    left join orders
        on lower(trim(api_logs.parent_type)) = 'tos_orders'
        and api_logs.parent_id = orders.order_id
    left join subscriptions
        on lower(trim(api_logs.parent_type)) = 'tos_subscriptions'
        and api_logs.parent_id = subscriptions.subscription_id
    left join customers
        on lower(trim(api_logs.parent_type)) = 'accounts'
        and api_logs.parent_id = customers.customer_id

),

enriched as (

    select
        api_logs.api_log_id,
        api_logs.api_log_name,
        api_logs.created_at,
        api_logs.updated_at,
        api_logs.api_status,
        api_logs.api_source,
        api_logs.parent_type,
        api_logs.parent_id,
        api_logs.error_details,
        api_logs.is_failure,
        partner_attribution.channel_partner_id,
        channel_partners.partner_name,
        (partner_attribution.channel_partner_id is not null) as has_partner_attribution

    from api_logs
    left join partner_attribution
        on api_logs.api_log_id = partner_attribution.api_log_id
    left join {{ ref('int_channel_partners') }} as channel_partners
        on partner_attribution.channel_partner_id = channel_partners.channel_partner_id

)

select * from enriched
