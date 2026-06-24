with orders as (

    select * from {{ ref('int_orders') }}

)

select
    orders.order_id,
    orders.created_at::date as order_date,
    orders.customer_id,
    orders.program_id,
    orders.channel_partner_id,
    orders.order_number,
    orders.order_status,
    orders.order_type,
    orders.sales_channel,
    orders.delivered_at,
    orders.first_paid_at,
    orders.is_preorder,
    orders.is_voided,
    orders.is_gmv_eligible,
    orders.has_valid_customer,
    orders.has_valid_program,
    orders.gmv_amount_sar,
    orders.total_discount_amount,
    orders.total_amount_incl_vat

from orders
