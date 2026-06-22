with date_spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2019-01-01' as date)",
        end_date="cast((current_date + interval '1 year') as date)"
    ) }}

),

enriched as (

    select
        date_spine.date_day as date_key,
        date_spine.date_day as full_date,
        extract(year from date_spine.date_day)::int as year_number,
        extract(quarter from date_spine.date_day)::int as quarter_number,
        extract(month from date_spine.date_day)::int as month_number,
        extract(day from date_spine.date_day)::int as day_of_month,
        extract(dow from date_spine.date_day)::int as day_of_week,
        to_char(date_spine.date_day, 'YYYY-MM') as year_month,
        to_char(date_spine.date_day, 'YYYY-"Q"Q') as year_quarter,
        (extract(dow from date_spine.date_day) in (0, 6)) as is_weekend

    from date_spine

)

select * from enriched
