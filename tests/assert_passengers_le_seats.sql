-- 业务级规则：旅客数不可能超过座位数
-- 这是 W8 讲的"业务级质量规则"——只有懂业务的人才写得出，工具生成不了
select
    flight_id,
    flight_date,
    carrier_code,
    seats,
    passengers
from {{ ref('stg_flights') }}
where passengers > seats
