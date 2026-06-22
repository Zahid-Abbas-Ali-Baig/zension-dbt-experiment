with source as (

    select * from {{ source('source', 'payments_subscribers') }}
    where deleted_at is null

),

renamed as (

    select
        id as subscriber_id,
        trim(stripe_id) as stripe_id,
        nullif(trim(default_payment_method_id), '') as default_payment_method_id,
        disputed,
        collectible,
        created_at,
        updated_at,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
