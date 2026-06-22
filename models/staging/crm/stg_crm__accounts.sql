with source as (

    select * from {{ source('source', 'crm_accounts') }}
    where deleted = false

),

renamed as (

    select
        id as customer_id,
        trim(name) as customer_name,
        date_entered as created_at,
        date_modified as updated_at,
        trim(national_id) as national_id,
        coalesce(nafath_verified, false) as is_nafath_verified,
        (trim(is_mobile_verified) ilike 'yes') as is_mobile_verified,
        nullif(trim(corporate_company_id), '') as corporate_company_id,
        nullif(trim(zoho_customer_id), '') as zoho_customer_id,
        nullif(trim(channel_partner_id), '') as channel_partner_id,
        nullif(trim(programs_customer_id), '') as program_id,
        trim(customer_uid) as customer_uid,
        trim(phone_number) as phone_number,
        trim(mobile_number) as mobile_number,
        trim(personal_email_address) as personal_email_address,
        lower(trim(customer_status)) as customer_status,
        customer_verification_at,
        nafath_verified_at,
        (
            coalesce(nafath_verified, false)
            and trim(is_mobile_verified) ilike 'yes'
        ) as is_fully_verified,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
