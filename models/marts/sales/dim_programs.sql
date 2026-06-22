with programs as (

    select * from {{ ref('int_programs') }}

)

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
    programs.partner_name,
    programs.partner_type,
    programs.active_subscription_count,
    programs.waiting_for_delivery_subscription_count,
    programs.utilization_subscription_count,
    programs.program_subscription_utilization_pct,
    programs.is_over_subscription_limit,
    programs.is_disabled_program,
    programs.has_valid_channel_partner,
    case
        when programs.is_disabled_program
            then 'disabled'
        when programs.is_over_subscription_limit
            then 'over_subscription_limit'
        when programs.is_fnf_program
            then 'fnf_pending_rules'
        else 'within_limit'
    end as program_limit_segment

from programs
