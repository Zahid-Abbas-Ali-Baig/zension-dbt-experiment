with source as (

    select * from {{ source('source', 'crm_tos_subscription_durations') }}
    where deleted = false

),

renamed as (

    select
        id as subscription_duration_id,
        trim(name) as subscription_duration_name,
        date_entered as created_at,
        date_modified as updated_at,
        duration::int as duration_months,
        lower(trim(duration_status)) as duration_status,
        nullif(trim(tos_programs_id), '') as program_id,
        nullif(trim(tos_channel_partners_id), '') as channel_partner_id,
        duration_start_date,
        duration_end_date,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
