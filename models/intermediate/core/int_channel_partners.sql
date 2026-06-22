with channel_partners as (

    select * from {{ ref('stg_crm__tos_channel_partners') }}

)

select
    channel_partner_id,
    partner_name,
    created_at,
    updated_at,
    legal_name,
    partner_type,
    vat_trn_number,
    channel_partner_uid,
    partner_status,
    country_id

from channel_partners
