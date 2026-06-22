with source as (

    select * from {{ source('source', 'payments_payment_methods') }}
    where deleted_at is null

),

renamed as (

    select
        id as psp_payment_method_id,
        nullif(trim(subscriber_id), '') as subscriber_id,
        is_enabled,
        expiry_month::int as expiry_month,
        expiry_year::int as expiry_year,
        trim(last4) as card_last_four,
        lower(trim(payment_gateway)) as payment_gateway,
        coalesce(expired, false) as is_expired,
        created_at,
        updated_at,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
