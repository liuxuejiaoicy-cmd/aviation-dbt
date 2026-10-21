-- 汇总层：航司 x 日，粒度 = 一行一个航司一天
-- 注意这里只放"可加度量"，不放客座率这类比率——比率的分子分母下标见 W5
{{ config(
    materialized='incremental',
    unique_key=['flight_date', 'carrier_code'],
    incremental_strategy='delete+insert'
) }}

with flights as (

    select * from {{ ref('stg_flights') }}

),

carriers as (

    select * from {{ ref('stg_carriers') }}

),

aggregated as (

    select
        f.flight_date,
        f.carrier_code,
        c.carrier_name,
        count(*)                                              as flight_count,
        count(*) filter (where not f.cancelled)                as operated_flights,
        sum(f.seats)                                          as seats_offered,
        sum(f.passengers)                                     as passengers_carried,
        sum(f.revenue)                                        as total_revenue,
        round(avg(f.dep_delay) filter (where not f.cancelled), 2) as avg_dep_delay_min
    from flights f
    left join carriers c
        on f.carrier_code = c.carrier_code
    group by 1, 2, 3

)

select * from aggregated

{% if is_incremental() %}
-- 增量模式：只处理新到达的日期
-- 首次运行时这张表还不存在，is_incremental() 返回 false，这段不会渲染
where flight_date > (select max(flight_date) from {{ this }})
{% endif %}
