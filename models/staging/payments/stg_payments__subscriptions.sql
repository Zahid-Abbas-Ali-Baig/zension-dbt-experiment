with source as (

    select * from {{ source('source', 'payments_subscriptions') }}
    where deleted_at is null

),

renamed as (

    select
        id as psp_subscription_id,
        lower(trim(currency)) as currency,
        locked as is_locked,
        nullif(trim(subscriber_id), '') as subscriber_id,
        created_at,
        updated_at,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
