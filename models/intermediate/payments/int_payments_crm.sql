with payments as (

    select * from {{ ref('stg_crm__tos_payments') }}

),

orders as (

    select * from {{ ref('int_orders') }}

),

customers as (

    select * from {{ ref('int_customers') }}

),

enriched as (

    select
        payments.payment_id,
        payments.payment_name,
        payments.created_at,
        payments.updated_at,
        payments.payment_status,
        payments.collected_amount_sar,
        payments.refund_amount_sar,
        payments.psp_payment_id,
        payments.order_id,
        payments.invoice_id,
        payments.customer_id,
        payments.subscription_id,
        payments.payment_timestamp,
        payments.paid_at,
        payments.payment_due_date,
        payments.payment_type,
        payments.is_recurring_payment,
        payments.refund_status,
        payments.is_collected,
        payments.is_failed,
        payments.is_refunded,
        orders.order_number,
        orders.program_id,
        orders.channel_partner_id,
        orders.partner_name,
        orders.program_name,
        orders.is_gmv_eligible,
        customers.customer_name,
        customers.is_fully_verified as customer_is_fully_verified,
        (orders.order_id is not null) as has_valid_order,
        (customers.customer_id is not null) as has_valid_customer

    from payments
    left join orders
        on payments.order_id = orders.order_id
    left join customers
        on payments.customer_id = customers.customer_id

)

select * from enriched
