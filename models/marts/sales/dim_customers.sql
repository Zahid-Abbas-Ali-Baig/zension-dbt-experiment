with customers as (

    select * from {{ ref('int_customers') }}

),

device_counts as (

    select * from {{ ref('int_customer_device_counts') }}

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
        customers.corporate_company_name,
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
        customers.allowed_email_domains,
        customers.company_status,
        customers.company_type,
        customers.has_valid_corporate_company,
        coalesce(device_counts.device_count, 0) as device_count,
        device_counts.first_device_purchase_date,
        device_counts.latest_device_delivery_date,
        case
            when customers.is_fully_verified
                then 'fully_verified'
            when customers.is_nafath_verified and not customers.is_mobile_verified
                then 'nafath_only'
            when customers.is_mobile_verified and not customers.is_nafath_verified
                then 'mobile_only'
            else 'unverified'
        end as customer_verification_segment

    from customers
    left join device_counts
        on customers.customer_id = device_counts.customer_id

)

select * from enriched
