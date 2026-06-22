with source as (

    select * from {{ source('source', 'payments_payments') }}
    where deleted_at is null

),

renamed as (

    select
        id as psp_payment_id,
        lower(trim(payment_type)) as payment_type,
        amount::numeric as payment_amount,
        subscriber_id,
        subscription_id as psp_subscription_id,
        transaction_id,
        payment_intent_id,
        due_date,
        created_at,
        updated_at,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
