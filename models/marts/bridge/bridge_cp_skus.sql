with cp_skus as (

    select * from {{ ref('stg_crm__tos_cp_skus') }}

),

device_skus as (

    select * from {{ ref('int_device_skus') }}

),

channel_partners as (

    select * from {{ ref('int_channel_partners') }}

),

enriched as (

    select
        cp_skus.cp_sku_id,
        cp_skus.channel_partner_id,
        cp_skus.zaam_sku_id,
        cp_skus.master_sku_id,
        cp_skus.cp_sku_name,
        cp_skus.cp_item_code,
        cp_skus.cp_sku_uid,
        cp_skus.category,
        cp_skus.purchase_price,
        cp_skus.created_at,
        cp_skus.updated_at,
        channel_partners.partner_name,
        channel_partners.partner_type,
        device_skus.brand,
        device_skus.model,
        device_skus.memory,
        device_skus.color,
        device_skus.device_sku_key,
        device_skus.master_sku_name,
        (channel_partners.channel_partner_id is not null) as has_valid_channel_partner,
        (device_skus.zaam_sku_id is not null) as has_valid_zaam_sku

    from cp_skus
    left join channel_partners
        on cp_skus.channel_partner_id = channel_partners.channel_partner_id
    left join device_skus
        on cp_skus.zaam_sku_id = device_skus.zaam_sku_id

)

select * from enriched
