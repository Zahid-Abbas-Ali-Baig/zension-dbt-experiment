with payments as (

    select * from {{ ref('int_payments_unified') }}

)

select
    payments.payment_id,
    payments.order_id,
    payments.invoice_id,
    payments.customer_id,
    payments.subscription_id,
    payments.program_id,
    payments.channel_partner_id,
    payments.psp_payment_id,
    payments.created_at::date as payment_date,
    payments.payment_timestamp,
    payments.paid_at,
    payments.payment_status,
    payments.payment_type,
    payments.refund_status,
    payments.is_collected,
    payments.is_failed,
    payments.is_refunded,
    payments.has_valid_order,
    payments.has_valid_customer,
    payments.is_psp_reconciled,
    payments.psp_reconciliation_status,
    payments.reconciliation_gap_reason,
    payments.collected_amount_sar,
    payments.refund_amount_sar,
    payments.psp_payment_amount

from payments
