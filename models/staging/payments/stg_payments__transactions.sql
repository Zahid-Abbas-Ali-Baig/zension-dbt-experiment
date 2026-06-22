with source as (

    select * from {{ source('source', 'payments_transactions') }}
    where _etl_deleted_at is null

),

renamed as (

    select
        id as transaction_id,
        lower(trim(process_status)) as process_status,
        lower(trim(request_status)) as request_status,
        nullif(trim(subscriber_id), '') as subscriber_id,
        nullif(trim(payment_intent_id), '') as payment_intent_id,
        lower(trim(type)) as transaction_type,
        is_scheduled,
        due_date,
        created_at,
        updated_at,
        (
            lower(trim(process_status)) = 'completed'
            and lower(trim(request_status)) = 'success'
        ) as is_successful,
        (lower(trim(process_status)) = 'queued') as is_retry_queue,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
