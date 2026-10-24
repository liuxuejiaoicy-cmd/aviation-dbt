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
        sum(f.dep_delay)            as total_dep_delay_min

        -- ③ 分子分母都留着，让下游自己算比率
        --    （客座率、准点率在这里不落库）

    from flights f
    left join carriers c
        on f.carrier_code = c.carrier_code
    group by 1, 2, 3

)

select * from aggregated

{% if is_incremental() %}
where flight_date > (select max(flight_date) from {{ this }})
{% endif %}
