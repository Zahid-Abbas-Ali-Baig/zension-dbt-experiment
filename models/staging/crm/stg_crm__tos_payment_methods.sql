with source as (

    select * from {{ source('source', 'crm_tos_payment_methods') }}
    where deleted = false

),

renamed as (

    select
        id as payment_method_id,
        trim(name) as payment_method_name,
        date_entered as created_at,
        date_modified as updated_at,
        nullif(trim(customer_id), '') as customer_id,
        lower(trim(status)) as payment_method_status,
        lower(trim(type)) as payment_method_type,
        trim(ending_digits) as card_last_four,
        expiry_year::int as expiry_year,
        expiry_month::int as expiry_month,
        is_default,
        lower(trim(payment_method_brand)) as card_brand,
        lower(trim(funding_type)) as funding_type,
        (
            expiry_year is not null
            and expiry_month is not null
            and make_date(expiry_year::int, expiry_month::int, 1) < date_trunc('month', current_date)
        ) as is_expired,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
