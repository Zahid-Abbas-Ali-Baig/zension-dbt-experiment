with attempts as (

    select * from {{ ref('int_payment_attempts') }}

)

select
    attempts.payment_history_id,
    attempts.payment_id,
    attempts.payment_method_id,
    attempts.order_id,
    attempts.customer_id,
    attempts.program_id,
    attempts.channel_partner_id,
    attempts.attempted_at::date as attempt_date,
    attempts.payment_attempt_status,
    attempts.error_code,
    attempts.error_reason,
    attempts.card_last_four,
    attempts.expiry_month,
    attempts.expiry_year,
    attempts.action,
    attempts.funding_type,
    attempts.is_successful_attempt,
    attempts.is_failed_attempt,
    attempts.is_recurring_installment,
    attempts.has_valid_payment,
    attempts.psp_reconciliation_status,
    attempts.psp_is_retry_queue,
    case
        when attempts.is_failed_attempt and attempts.psp_is_retry_queue
            then 1
        else 0
    end as is_retry_indicator

from attempts
