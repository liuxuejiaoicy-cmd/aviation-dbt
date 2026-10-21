-- 粒度唯一性测试：航司 x 日 的组合必须唯一
-- 约定：返回的行 = 失败的行。这里能查出重复，就说明 group by 漏了维度
select
    flight_date,
    carrier_code,
    count(*) as row_count
from {{ ref('mart_carrier_daily') }}
group by 1, 2
having count(*) > 1
