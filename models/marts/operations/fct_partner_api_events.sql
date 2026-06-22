with api_events as (

    select * from {{ ref('int_partner_api_events') }}

)

select
    api_events.api_log_id,
    api_events.channel_partner_id,
    api_events.created_at::date as event_date,
    api_events.api_status,
    api_events.api_source,
    api_events.parent_type,
    api_events.parent_id,
    api_events.error_details,
    api_events.is_failure,
    api_events.has_partner_attribution,
    case when api_events.is_failure then 1 else 0 end as failure_count

from api_events
