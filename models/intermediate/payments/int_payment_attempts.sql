with payment_history as (

    select * from {{ ref('stg_crm__tos_payment_history') }}

),

crm_payments as (

    select
        payment_id,
        is_recurring_payment
    from {{ ref('stg_crm__tos_payments') }}

),

unified_payments as (

    select * from {{ ref('int_payments_unified') }}

),

enriched as (

    select
        payment_history.payment_history_id,
        payment_history.payment_history_name,
        payment_history.created_at,
        payment_history.updated_at,
        payment_history.payment_attempt_status,
        payment_history.payment_id,
        payment_history.payment_method_id,
        payment_history.error_code,
        payment_history.error_reason,
        payment_history.card_last_four,
        payment_history.expiry_month,
        payment_history.expiry_year,
        payment_history.action,
        payment_history.funding_type,
        payment_history.attempted_at,
        payment_history.refund_id,
        payment_history.is_successful_attempt,
        payment_history.is_failed_attempt,
        coalesce(crm_payments.is_recurring_payment, false) as is_recurring_installment,
        unified_payments.order_id,
        unified_payments.customer_id,
        unified_payments.program_id,
        unified_payments.channel_partner_id,
        unified_payments.partner_name,
        unified_payments.psp_reconciliation_status,
        unified_payments.psp_is_retry_queue,
        (unified_payments.payment_id is not null) as has_valid_payment

    from payment_history
    left join crm_payments
        on payment_history.payment_id = crm_payments.payment_id
    left join unified_payments
        on payment_history.payment_id = unified_payments.payment_id

)

select * from enriched
