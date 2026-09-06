-- Date dimension table: one row per calendar date (2023-2025)
-- Built using dbt_utils.date_spine instead of external date package

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2023-01-01' as date)",
        end_date="cast('2025-12-31' as date)"
    ) }}
),

dates as (
    select
        cast(date_day as date) as date_day
    from date_spine
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['date_day']) }}    as date_key,
        date_day,
        extract(year from date_day)                             as year_number,
        extract(month from date_day)                            as month_number,
        extract(day from date_day)                              as day_of_month,
        extract(quarter from date_day)                          as quarter_number,
        extract(dayofweek from date_day)                        as day_of_week,
        extract(week from date_day)                             as week_of_year,
        to_char(date_day, 'MMMM')                               as month_name,
        to_char(date_day, 'Mon')                                 as month_short,
        to_char(date_day, 'Dy')                                  as day_name_short,
        to_char(date_day, 'Day')                                 as day_name,
        case 
            when extract(dayofweek from date_day) in (0, 6) then true
            else false
        end                                                     as is_weekend,
        'Q' || extract(quarter from date_day)                   as quarter_label,
        extract(year from date_day) || '-Q' || extract(quarter from date_day) as year_quarter

    from dates
)

select * from final
