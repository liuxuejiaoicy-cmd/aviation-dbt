{{ config(
    materialized='incremental',
    unique_key=['flight_date', 'carrier_code'],
    incremental_strategy='delete+insert'
) }}
with flights as (

    select  * from {{ ref('stg_flights') }}

),

carriers as (

    select  * from {{ ref('stg_carriers') }}

),

aggregated as (

    select
        f.flight_date,
        f.carrier_code,
        c.carrier_name,

        -- ① 计数类
        count(*)                        as flight_count,
        sum(f.cancelled)                as cancelled_count,

        -- ② 可加度量（能直接 SUM 的）
        sum(f.passengers)               as total_passengers,
        sum(f.seats)                    as total_seats,
        sum(f.revenue)                  as total_revenue,
        sum(f.dep_delay)            as total_dep_delay_min,

        -- ③ 比率的分子分母（必须留，上层汇总全靠它们）
        sum(case when f.cancelled = 0 then 1 else 0 end)
                                        as completed_flights,
        sum(case when f.cancelled = 0 and f.dep_delay <= 15 then 1 else 0 end)
                                        as on_time_flights,

        -- ④ 比率本身（用 ③ 现算，不要自己再 sum 一遍）
        {{ load_factor('sum(f.passengers)', 'sum(f.seats)') }}
                                        as load_factor_pct,
        round(100.0 * sum(case when f.cancelled = 0 and f.dep_delay <= 15 then 1 else 0 end)
              / nullif(sum(case when f.cancelled = 0 then 1 else 0 end), 0), 2)
                                        as on_time_rate_pct
    from flights f
    left join carriers c
        on f.carrier_code = c.carrier_code
    group by 1, 2, 3

)

select * from aggregated

{% if is_incremental() %}
where flight_date > (select max(flight_date) from {{ this }})
{% endif %}
