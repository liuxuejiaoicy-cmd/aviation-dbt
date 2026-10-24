with source as (
    select * from {{ source('raw', 'raw_carriers') }}
),
renamed as (
    select
        upper(trim(carrier_code)) as carrier_code,
        carrier_name,
        country
    from source
)
select * from renamed
