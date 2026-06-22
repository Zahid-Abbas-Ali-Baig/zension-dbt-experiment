with transactions as (

    select * from {{ ref('stg_payments__transactions') }}

),

psp_payments as (

    select
        psp_payment_id,
        transaction_id,
        payment_amount,
        psp_subscription_id,
        row_number() over (
            partition by transaction_id
            order by psp_payment_id
        ) as transaction_match_rank

    from {{ ref('int_payments_psp') }}
    where transaction_id is not null

),

psp_payments_deduped as (

    select
        psp_payment_id,
        transaction_id,
        payment_amount,
        psp_subscription_id

    from psp_payments
    where transaction_match_rank = 1

),

enriched as (

    select
        transactions.transaction_id,
        transactions.subscriber_id,
        transactions.payment_intent_id,
        transactions.created_at::date as transaction_date,
        transactions.process_status,
        transactions.request_status,
        transactions.transaction_type,
        transactions.is_scheduled,
        transactions.is_successful,
        transactions.is_retry_queue,
        psp_payments_deduped.psp_payment_id,
        psp_payments_deduped.payment_amount,
        psp_payments_deduped.psp_subscription_id,
        case
            when transactions.is_successful
                then 'successful'
            when transactions.is_retry_queue
                then 'retry_queue'
            else 'failed'
        end as transaction_outcome_segment

    from transactions
    left join psp_payments_deduped
        on transactions.transaction_id = psp_payments_deduped.transaction_id

)

select * from enriched
