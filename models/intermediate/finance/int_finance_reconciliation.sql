{{
    config(
        description='Monthly reconciliation of CRM collected revenue vs Zoho-synced '
        'invoiced revenue. Collected sums paid CRM payments by payment_timestamp month; '
        'invoiced sums paid aos_invoices by invoice_date month. finance_variance_sar '
        'is collected minus invoiced per KPI map Q7.'
    )
}}

with monthly_collected as (

    select
        date_trunc('month', payments.payment_timestamp)::date as reconciliation_month,
        sum(payments.collected_amount_sar) filter (where payments.is_collected) as collected_revenue_sar,
        count(*) filter (where payments.is_collected) as collected_payment_count,
        sum(payments.refund_amount_sar) filter (where payments.is_refunded) as crm_refund_amount_sar

    from {{ ref('int_payments_unified') }} as payments
    where payments.payment_timestamp is not null
    group by 1

),

monthly_invoiced as (

    select
        date_trunc('month', invoices.invoice_date)::date as reconciliation_month,
        sum(invoices.invoice_amount_sar) filter (where invoices.is_paid) as invoiced_revenue_sar,
        count(*) filter (where invoices.is_paid) as paid_invoice_count,
        sum(invoices.invoice_amount_sar) filter (where not invoices.is_paid) as unpaid_invoice_amount_sar

    from {{ ref('int_invoices') }} as invoices
    where invoices.invoice_date is not null
    group by 1

),

monthly_credit_notes as (

    select
        date_trunc('month', credit_notes.created_at)::date as reconciliation_month,
        count(*) as credit_note_count

    from {{ ref('int_credit_notes') }} as credit_notes
    group by 1

),

months as (

    select reconciliation_month from monthly_collected
    union
    select reconciliation_month from monthly_invoiced
    union
    select reconciliation_month from monthly_credit_notes

),

reconciled as (

    select
        months.reconciliation_month,
        coalesce(monthly_collected.collected_revenue_sar, 0) as collected_revenue_sar,
        coalesce(monthly_invoiced.invoiced_revenue_sar, 0) as invoiced_revenue_sar,
        coalesce(monthly_collected.collected_revenue_sar, 0)
            - coalesce(monthly_invoiced.invoiced_revenue_sar, 0) as finance_variance_sar,
        coalesce(monthly_collected.collected_payment_count, 0) as collected_payment_count,
        coalesce(monthly_invoiced.paid_invoice_count, 0) as paid_invoice_count,
        coalesce(monthly_invoiced.unpaid_invoice_amount_sar, 0) as unpaid_invoice_amount_sar,
        coalesce(monthly_collected.crm_refund_amount_sar, 0) as crm_refund_amount_sar,
        coalesce(monthly_credit_notes.credit_note_count, 0) as credit_note_count

    from months
    left join monthly_collected
        on months.reconciliation_month = monthly_collected.reconciliation_month
    left join monthly_invoiced
        on months.reconciliation_month = monthly_invoiced.reconciliation_month
    left join monthly_credit_notes
        on months.reconciliation_month = monthly_credit_notes.reconciliation_month

)

select * from reconciled
