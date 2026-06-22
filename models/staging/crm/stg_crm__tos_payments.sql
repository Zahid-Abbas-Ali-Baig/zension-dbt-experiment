with source as (

    select * from {{ source('source', 'crm_tos_payments') }}
    where deleted = false

),

renamed as (

    select
        id as payment_id,
        trim(name) as payment_name,
        date_entered as created_at,
        date_modified as updated_at,
        lower(trim(payment_status)) as payment_status,
        payment_amount_tax_inclusive::numeric as collected_amount_sar,
        refund_amount::numeric as refund_amount_sar,
        nullif(trim(payment_id), '') as psp_payment_id,
        nullif(trim(order_id), '') as order_id,
        nullif(trim(invoice_id), '') as invoice_id,
        nullif(trim(customer_payment_id), '') as customer_id,
        nullif(trim(subscription_payment_id), '') as subscription_id,
        payment_timestamp,
        payment_due_date,
        lower(trim(payment_type)) as payment_type,
        lower(trim(refund_status)) as refund_status,
        (lower(trim(payment_status)) = 'paid') as is_collected,
        (lower(trim(payment_status)) = 'failed') as is_failed,
        (lower(trim(payment_status)) = 'refunded') as is_refunded,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
