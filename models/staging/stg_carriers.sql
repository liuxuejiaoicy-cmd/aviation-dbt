with source as (

    select * from {{ source('raw', 'raw_carriers') }}

),

cleaned as (

    select
        upper(trim(carrier_code)) as carrier_code,
        trim(carrier_name)        as carrier_name,
        upper(trim(country))      as country
    from source

)

select * from cleaned
