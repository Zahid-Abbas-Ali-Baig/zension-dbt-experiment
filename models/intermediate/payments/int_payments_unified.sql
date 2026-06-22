{{
    config(
        description='Unifies CRM payment records with Payment Service intents. '
        'CRM is the grain; PSP rows are left-joined on psp_payment_id. '
        'psp_reconciliation_status flags orphans per design brief (141 missing_in_psp).'
    )
}}

with crm_payments as (

    select * from {{ ref('int_payments_crm') }}

),

psp_payments as (

    select * from {{ ref('int_payments_psp') }}

),

unified as (

    select
        crm_payments.payment_id,
        crm_payments.payment_name,
        crm_payments.created_at,
        crm_payments.updated_at,
        crm_payments.payment_status,
        crm_payments.collected_amount_sar,
        crm_payments.refund_amount_sar,
        crm_payments.psp_payment_id,
        crm_payments.order_id,
        crm_payments.invoice_id,
        crm_payments.customer_id,
        crm_payments.subscription_id,
        crm_payments.payment_timestamp,
        crm_payments.payment_due_date,
        crm_payments.payment_type,
        crm_payments.refund_status,
        crm_payments.is_collected,
        crm_payments.is_failed,
        crm_payments.is_refunded,
        crm_payments.order_number,
        crm_payments.program_id,
        crm_payments.channel_partner_id,
        crm_payments.partner_name,
        crm_payments.program_name,
        crm_payments.customer_name,
        crm_payments.has_valid_order,
        crm_payments.has_valid_customer,
        psp_payments.payment_amount as psp_payment_amount,
        psp_payments.payment_intent_id,
        psp_payments.subscriber_id,
        psp_payments.psp_subscription_id,
        psp_payments.process_status as psp_process_status,
        psp_payments.request_status as psp_request_status,
        psp_payments.is_successful as psp_is_successful,
        psp_payments.is_retry_queue as psp_is_retry_queue,
        (psp_payments.psp_payment_id is not null) as is_psp_reconciled,
        case
            when crm_payments.psp_payment_id is null
                or trim(crm_payments.psp_payment_id) = ''
                then 'no_psp_reference'
            when psp_payments.psp_payment_id is null
                then 'missing_in_psp'
            when crm_payments.collected_amount_sar is distinct from psp_payments.payment_amount
                then 'amount_mismatch'
            else 'reconciled'
        end as psp_reconciliation_status,
        case
            when crm_payments.psp_payment_id is null
                or trim(crm_payments.psp_payment_id) = ''
                then 'CRM payment has no PSP payment_id reference'
            when psp_payments.psp_payment_id is null
                then 'PSP payment record not found for CRM payment_id'
            when crm_payments.collected_amount_sar is distinct from psp_payments.payment_amount
                then 'CRM collected amount differs from PSP payment amount'
        end as reconciliation_gap_reason

    from crm_payments
    left join psp_payments
        on crm_payments.psp_payment_id = psp_payments.psp_payment_id

)

select * from unified
