with source as (

    select * from {{ source('source', 'crm_tos_api_logs') }}
    where deleted = false

),

renamed as (

    select
        id as api_log_id,
        trim(name) as api_log_name,
        date_entered as created_at,
        date_modified as updated_at,
        lower(trim(status)) as api_status,
        lower(trim(source)) as api_source,
        trim(parent_type) as parent_type,
        nullif(trim(parent_id), '') as parent_id,
        trim(error_details) as error_details,
        (lower(trim(status)) = 'failure') as is_failure,
        _etl_synced_at,
        _etl_source_system

    from source

)

select * from renamed
