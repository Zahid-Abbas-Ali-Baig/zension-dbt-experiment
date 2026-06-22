with corporate_companies as (

    select * from {{ ref('stg_crm__tos_corporate_company') }}

),

verified_customers as (

    select
        corporate_company_id,
        count(*) filter (where is_fully_verified) as verified_customer_count,
        count(*) as customer_count

    from {{ ref('int_customers') }}
    where corporate_company_id is not null
    group by 1

),

enriched as (

    select
        corporate_companies.corporate_company_id,
        corporate_companies.company_name,
        corporate_companies.created_at,
        corporate_companies.updated_at,
        corporate_companies.allowed_email_domains,
        corporate_companies.company_status,
        corporate_companies.channel_partner_id,
        corporate_companies.company_type,
        coalesce(verified_customers.verified_customer_count, 0) as verified_customer_count,
        coalesce(verified_customers.customer_count, 0) as customer_count,
        case
            when coalesce(verified_customers.verified_customer_count, 0) > 0
                then 'has_verified_customers'
            when coalesce(verified_customers.customer_count, 0) > 0
                then 'has_unverified_customers'
            else 'no_customers'
        end as cep_verification_segment

    from corporate_companies
    left join verified_customers
        on corporate_companies.corporate_company_id = verified_customers.corporate_company_id

)

select * from enriched
