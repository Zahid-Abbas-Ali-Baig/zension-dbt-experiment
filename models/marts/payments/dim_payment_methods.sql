with crm_methods as (

    select
        payment_method_id as payment_method_key,
        'crm'::text as payment_method_source,
        payment_method_id,
        null::text as psp_payment_method_id,
        customer_id,
        null::text as subscriber_id,
        payment_method_name,
        payment_method_status,
        payment_method_type,
        card_last_four,
        expiry_year,
        expiry_month,
        is_default,
        card_brand,
        funding_type,
        is_expired,
        created_at,
        updated_at

    from {{ ref('stg_crm__tos_payment_methods') }}

),

psp_methods as (

    select
        psp_payment_method_id as payment_method_key,
        'psp'::text as payment_method_source,
        null::text as payment_method_id,
        psp_payment_method_id,
        null::text as customer_id,
        subscriber_id,
        null::text as payment_method_name,
        case when is_enabled then 'active' else 'disabled' end as payment_method_status,
        payment_gateway as payment_method_type,
        card_last_four,
        expiry_year,
        expiry_month,
        false as is_default,
        payment_gateway as card_brand,
        null::text as funding_type,
        is_expired,
        created_at,
        updated_at

    from {{ ref('stg_payments__payment_methods') }}

),

unified as (

    select * from crm_methods
    union all
    select * from psp_methods

)

select
    unified.*,
    case
        when unified.is_expired
            then 'expired'
        when unified.payment_method_status in ('active', 'enabled')
            then 'active'
        else 'inactive'
    end as payment_method_health_segment

from unified
