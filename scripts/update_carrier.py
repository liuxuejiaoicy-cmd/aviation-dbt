"""
模拟航司改名：修改 raw_carriers 里某个航司的名称。

用途：演示 SCD Type 2 —— 航司属性变了，快照表应该"加一行新版本"，
      而不是把旧名称覆盖掉（那叫 SCD Type 1）。

用法：python scripts/update_carrier.py AA "American Airlines Inc"
"""

import sys
from pathlib import Path

import duckdb

BASE = Path(__file__).resolve().parent.parent
DB = BASE / "aviation.duckdb"

code = sys.argv[1] if len(sys.argv) > 1 else "AA"
new_name = sys.argv[2] if len(sys.argv) > 2 else "American Airlines Inc"

con = duckdb.connect(str(DB))

before = con.execute(
    "select carrier_code, carrier_name from raw_carriers where carrier_code = ?", [code]
).fetchone()
print("改名前:", before)

con.execute(
    "UPDATE raw_carriers SET carrier_name = ? WHERE carrier_code = ?", [new_name, code]
)

after = con.execute(
    "select carrier_code, carrier_name from raw_carriers where carrier_code = ?", [code]
).fetchone()
print("改名后:", after)

con.close()
