-- 清洗层：对应你熟悉的 ODS -> DWD 那一步
-- 铁律：只改名、只改类型、只做行级清洗，不做聚合、不做业务判断
with source as (

    select * from {{ source('raw', 'raw_flights') }}

),

cleaned as (

    select
        flight_id,
        cast(flight_date as date)            as flight_date,
        upper(trim(carrier_code))            as carrier_code,
        upper(trim(origin))                  as origin,
        upper(trim(dest))                    as dest,
        cast(distance as integer)            as distance,
        cast(seats as integer)               as seats,
        cast(passengers as integer)          as passengers,
        cast(dep_delay as integer)           as dep_delay,
        cast(arr_delay as integer)           as arr_delay,
        cast(cancelled as integer) = 1       as cancelled,
        cast(revenue as double)              as revenue,
        cast(carrier_delay as integer)       as carrier_delay,
        cast(weather_delay as integer)       as weather_delay,
        cast(nas_delay as integer)           as nas_delay,
        cast(security_delay as integer)      as security_delay,
        cast(late_aircraft_delay as integer) as late_aircraft_delay
    from source

)

select * from cleaned
