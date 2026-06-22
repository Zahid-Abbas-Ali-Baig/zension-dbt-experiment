with reconciliation as (

    select * from {{ ref('int_finance_reconciliation') }}

)

select
    reconciliation.reconciliation_month,
    reconciliation.collected_revenue_sar,
    reconciliation.invoiced_revenue_sar,
    reconciliation.finance_variance_sar,
    reconciliation.collected_payment_count,
    reconciliation.paid_invoice_count,
    reconciliation.unpaid_invoice_amount_sar,
    reconciliation.crm_refund_amount_sar,
    reconciliation.credit_note_count

from reconciliation
