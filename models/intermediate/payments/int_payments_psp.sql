with psp_payments as (

    select * from {{ ref('stg_payments__payments') }}

),

transactions as (

    select * from {{ ref('stg_payments__transactions') }}

),

enriched as (

    select
        psp_payments.psp_payment_id,
        psp_payments.payment_type,
        psp_payments.payment_amount,
        psp_payments.subscriber_id,
        psp_payments.psp_subscription_id,
        psp_payments.transaction_id,
        psp_payments.payment_intent_id,
        psp_payments.due_date,
        psp_payments.created_at,
        psp_payments.updated_at,
        transactions.process_status,
        transactions.request_status,
        transactions.transaction_type,
        transactions.is_scheduled,
        transactions.is_successful,
        transactions.is_retry_queue,
        (transactions.transaction_id is not null) as has_transaction_outcome

    from psp_payments
    left join transactions
        on psp_payments.transaction_id = transactions.transaction_id

)

select * from enriched
