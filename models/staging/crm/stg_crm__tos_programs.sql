with source as (

    select * from {{ source('source', 'crm_tos_programs') }}
    where deleted = false

),

renamed as (

    select
        id as program_id,
        trim(name) as program_name,
        date_entered as created_at,
        date_modified as updated_at,
        lower(trim(program_status)) as program_status,
        nullif(trim(channel_partner_id), '') as channel_partner_id,
        trim(program_uid) as program_uid,
        subscription_limit::int as subscription_limit,
        payment_methods_limit::int as payment_methods_limit,
        program_start_date,
        program_end_date,
        (trim(name) ilike '%fnf%') as is_fnf_program,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
