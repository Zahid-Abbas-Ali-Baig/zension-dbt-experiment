with source as (

    select * from {{ source('source', 'crm_tos_invoice_line_items') }}
    where deleted = false

),

renamed as (

    select
        id as invoice_line_item_id,
        trim(name) as invoice_line_item_name,
        date_entered as created_at,
        date_modified as updated_at,
        nullif(trim(tos_subscriptions_id), '') as subscription_id,
        nullif(trim(tos_order_item_id), '') as order_item_id,
        nullif(trim(line_item_id), '') as line_item_id,
        nullif(trim(invoice_line_item_id), '') as parent_invoice_line_item_id,
        amount::numeric as line_amount_sar,
        amount_ex_vat::numeric as line_amount_ex_vat_sar,
        vat_amount::numeric as vat_amount_sar,
        total_inc_vat::numeric as line_amount_incl_vat_sar,
        quantity::numeric as quantity,
        lower(trim(product_type)) as product_type,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
