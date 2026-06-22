with customers as (

    select * from {{ ref('stg_crm__accounts') }}

),

corporate_companies as (

    select * from {{ ref('stg_crm__tos_corporate_company') }}

),

enriched as (

    select
        customers.customer_id,
        customers.customer_name,
        customers.created_at,
        customers.updated_at,
        customers.national_id,
        customers.is_nafath_verified,
        customers.is_mobile_verified,
        customers.is_fully_verified,
        customers.corporate_company_id,
        customers.zoho_customer_id,
        customers.channel_partner_id,
        customers.program_id,
        customers.customer_uid,
        customers.phone_number,
        customers.mobile_number,
        customers.personal_email_address,
        customers.customer_status,
        customers.customer_verification_at,
        customers.nafath_verified_at,
        corporate_companies.company_name as corporate_company_name,
        corporate_companies.allowed_email_domains,
        corporate_companies.company_status,
        corporate_companies.company_type,
        (corporate_companies.corporate_company_id is not null) as has_valid_corporate_company

    from customers
    left join corporate_companies
        on customers.corporate_company_id = corporate_companies.corporate_company_id

)

select * from enriched
