select
    payments.payment_id as refund_event_id,
    'crm'::text as refund_source,
    payments.refund_amount_sar,
    payments.paid_at as refunded_at,
    payments.customer_id,
    payments.order_id,
    payments.channel_partner_id,
    payments.program_id,
    payments.partner_name,
    md5('crm' || payments.payment_id::text) as refund_dedup_key

from {{ ref('int_payments_crm') }} as payments
where payments.is_refunded
    and coalesce(payments.refund_amount_sar, 0) > 0
