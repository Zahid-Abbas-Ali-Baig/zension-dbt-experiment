with orders as (

    select * from {{ ref('stg_crm__tos_orders') }}

),

programs as (

    select * from {{ ref('int_programs') }}

),

customers as (

    select * from {{ ref('int_customers') }}

),

enriched as (

    select
        orders.order_id,
        orders.order_number,
        orders.created_at,
        orders.updated_at,
        orders.order_status,
        orders.order_type,
        orders.gmv_amount_sar,
        orders.customer_id,
        orders.program_id,
        orders.delivered_at,
        orders.sales_channel,
        orders.payment_method_id,
        orders.total_discount_amount,
        orders.total_amount_incl_vat,
        orders.is_preorder,
        orders.is_voided,
        orders.is_gmv_eligible,
        programs.program_name,
        programs.channel_partner_id,
        programs.partner_name,
        programs.partner_type,
        programs.is_fnf_program,
        customers.customer_name,
        customers.is_fully_verified as customer_is_fully_verified,
        customers.corporate_company_id,
        customers.corporate_company_name,
        (customers.customer_id is not null) as has_valid_customer,
        (programs.program_id is not null) as has_valid_program,
        (programs.channel_partner_id is not null) as has_valid_channel_partner

    from orders
    left join programs
        on orders.program_id = programs.program_id
    left join customers
        on orders.customer_id = customers.customer_id

)

select * from enriched
