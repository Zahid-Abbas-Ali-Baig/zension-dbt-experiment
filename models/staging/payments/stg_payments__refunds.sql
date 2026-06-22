with source as (

    select * from {{ source('source', 'payments_refunds') }}
    where _etl_deleted_at is null

),

renamed as (

    select
        id as refund_record_id,
        trim(refund_id) as psp_refund_id,
        nullif(trim(payment_intent_id), '') as payment_intent_id,
        amount::numeric as refund_amount,
        lower(trim(status)) as refund_status,
        lower(trim(currency)) as currency,
        created_at,
        updated_at,
        (lower(trim(status)) = 'approved') as is_approved,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
