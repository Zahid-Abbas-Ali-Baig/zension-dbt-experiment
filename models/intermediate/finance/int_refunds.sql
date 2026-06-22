with crm_refunds as (

    select
        payments.payment_id as refund_event_id,
        'crm'::text as refund_source,
        payments.refund_amount_sar,
        payments.payment_timestamp as refunded_at,
        payments.customer_id,
        payments.order_id,
        payments.channel_partner_id,
        payments.program_id,
        payments.partner_name,
        md5('crm' || payments.payment_id::text) as refund_dedup_key

    from {{ ref('int_payments_crm') }} as payments
    where payments.is_refunded
        and coalesce(payments.refund_amount_sar, 0) > 0

),

psp_refunds as (

    select
        refunds.refund_record_id as refund_event_id,
        'psp'::text as refund_source,
        refunds.refund_amount as refund_amount_sar,
        refunds.created_at as refunded_at,
        null::text as customer_id,
        null::text as order_id,
        null::text as channel_partner_id,
        null::text as program_id,
        null::text as partner_name,
        md5(
            'psp' || coalesce(refunds.psp_refund_id, refunds.refund_record_id::text)
        ) as refund_dedup_key

    from {{ ref('stg_payments__refunds') }} as refunds
    where refunds.is_approved

),

unioned as (

    select * from crm_refunds
    union all
    select * from psp_refunds

)

select * from unioned
