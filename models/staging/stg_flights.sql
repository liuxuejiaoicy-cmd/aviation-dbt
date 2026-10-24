-- 第 1 层：取数。只做一件事——声明数据从哪来
with source as (

    select * from {{ source('raw', 'raw_flights') }}

),

-- 第 2 层：加工。改名、转类型、行级清洗，全在这里
renamed as (

    select
        -- ① 主键：原样保留，不改
        flight_id,

        -- ② 时间列：统一转成 date 类型
        cast(flight_date as date)          as flight_date,

        -- ③ 代码类列：去空格 + 统一大写（航司代码、机场代码）
        upper(trim(carrier_code))          as carrier_code,
        upper(trim(origin))        as origin_airport,
        upper(trim(dest))          as dest_airport,

        -- ④ 数值列：显式转类型，避免上游传来字符串
        cast(seats as integer)             as seats,
        cast(passengers as integer)        as passengers,
        cast(revenue as decimal(18,2))     as revenue,

        -- ⑤ 其余列原样带过来
        distance,
        dep_delay,
        arr_delay,
        cancelled,
        carrier_delay,
        weather_delay,
        nas_delay,
        security_delay,
        late_aircraft_delay
    from source

)

-- 第 3 层：输出。staging 的铁律——这里没有 group by
select * from renamed
