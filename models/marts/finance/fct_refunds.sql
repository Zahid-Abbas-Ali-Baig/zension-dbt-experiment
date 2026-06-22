with refunds as (

    select * from {{ ref('int_refunds') }}

)

select
    refunds.refund_dedup_key as refund_id,
    refunds.refund_event_id,
    refunds.refund_source,
    refunds.refund_amount_sar,
    refunds.refunded_at::date as refund_date,
    refunds.refunded_at,
    refunds.customer_id,
    refunds.order_id,
    refunds.channel_partner_id,
    refunds.program_id,
    refunds.partner_name

from refunds
