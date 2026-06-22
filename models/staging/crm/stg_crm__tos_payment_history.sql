with source as (

    select * from {{ source('source', 'crm_tos_payment_history') }}
    where deleted = false

),

renamed as (

    select
        id as payment_history_id,
        trim(name) as payment_history_name,
        date_entered as created_at,
        date_modified as updated_at,
        lower(trim(status)) as payment_attempt_status,
        nullif(trim(payment_id), '') as payment_id,
        nullif(trim(payment_method_id), '') as payment_method_id,
        trim(error_code) as error_code,
        trim(error_reason) as error_reason,
        trim(last_four) as card_last_four,
        expiry_month,
        expiry_year,
        lower(trim(action)) as action,
        lower(trim(funding_type)) as funding_type,
        attempted_at,
        trim(refund_id) as refund_id,
        (lower(trim(status)) in ('paid', 'approved')) as is_successful_attempt,
        (lower(trim(status)) = 'failed') as is_failed_attempt,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
