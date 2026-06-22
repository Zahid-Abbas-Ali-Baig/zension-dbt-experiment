with order_items as (

    select * from {{ ref('int_order_items') }}

)

select
    order_items.order_item_id,
    order_items.order_id,
    order_items.customer_id,
    order_items.program_id,
    order_items.channel_partner_id,
    order_items.master_sku_id,
    order_items.resolved_zaam_sku_id as zaam_sku_id,
    order_items.device_sku_key,
    order_items.created_at::date as order_item_date,
    order_items.quantity,
    order_items.unit_price_vat_inclusive,
    order_items.total_price_vat_inclusive,
    order_items.device_purchase_price_vat_inclusive,
    order_items.discount_amount,
    order_items.product_type,
    order_items.order_line_item_type,
    order_items.brand,
    order_items.model,
    order_items.memory,
    order_items.color,
    order_items.has_valid_order,
    order_items.has_valid_resolved_sku

from order_items
