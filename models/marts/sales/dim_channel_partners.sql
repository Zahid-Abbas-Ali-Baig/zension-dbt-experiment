with channel_partners as (

    select * from {{ ref('int_channel_partners') }}

),

api_events as (

    select
        channel_partner_id,
        count(*) as api_call_count,
        count(*) filter (where is_failure) as api_failure_count,
        case
            when count(*) > 0
                then round(
                    count(*) filter (where is_failure)::numeric / count(*)::numeric,
                    4
                )
        end as partner_api_failure_rate

    from {{ ref('int_partner_api_events') }}
    where channel_partner_id is not null
    group by 1

),

enriched as (

    select
        channel_partners.channel_partner_id,
        channel_partners.partner_name,
        channel_partners.created_at,
        channel_partners.updated_at,
        channel_partners.legal_name,
        channel_partners.partner_type,
        channel_partners.vat_trn_number,
        channel_partners.channel_partner_uid,
        channel_partners.partner_status,
        channel_partners.country_id,
        coalesce(api_events.api_call_count, 0) as api_call_count,
        coalesce(api_events.api_failure_count, 0) as api_failure_count,
        api_events.partner_api_failure_rate,
        case
            when coalesce(api_events.partner_api_failure_rate, 0) > 0
                then 'elevated_api_failures'
            when coalesce(api_events.api_call_count, 0) = 0
                then 'no_api_activity'
            else 'healthy_api_performance'
        end as partner_operations_segment

    from channel_partners
    left join api_events
        on channel_partners.channel_partner_id = api_events.channel_partner_id

)

select * from enriched
