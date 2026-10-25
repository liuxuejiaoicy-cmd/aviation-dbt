-- 客座率不可能 < 0，也不可能 > 100（出现即说明分子分母算错或上游数据脏）
-- singular test 规则：查出 0 行 = 通过，查出任何一行 = 失败
select
    flight_date,
    carrier_code,
    load_factor_pct
from {{ ref('mart_carrier_daily') }}
where load_factor_pct < 0
   or load_factor_pct > 100