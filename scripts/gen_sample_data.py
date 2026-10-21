"""
W3 样例数据生成器。

作用：模拟 EL（抽取 + 加载）环节——在 dbt 之外，把原始数据落进 DuckDB。
dbt 负责的是之后那一步 T（转换），这个边界要分清。

真实项目中，这一步由 Fivetran / Airbyte / 自写脚本 / Informatica 完成。
这里用固定随机种子造 128 行航班数据，保证每次生成结果一致、可复现。
"""

import csv
import random
from pathlib import Path

import duckdb

BASE = Path(__file__).resolve().parent.parent
DATA_DIR = BASE / "data"
DATA_DIR.mkdir(exist_ok=True)

random.seed(42)

CARRIERS = [
    ("AA", "American Airlines", "US"),
    ("DL", "Delta Air Lines", "US"),
    ("UA", "United Airlines", "US"),
    ("WN", "Southwest Airlines", "US"),
]

ROUTES = [
    ("DFW", "LAX", 1235),
    ("ATL", "JFK", 760),
    ("ORD", "DEN", 888),
    ("SEA", "SFO", 679),
]

DATES = [f"2024-01-{d:02d}" for d in range(1, 9)]  # 8 天

FLIGHT_HEADER = [
    "flight_id", "flight_date", "carrier_code", "origin", "dest", "distance",
    "seats", "passengers", "dep_delay", "arr_delay", "cancelled", "revenue",
    "carrier_delay", "weather_delay", "nas_delay", "security_delay",
    "late_aircraft_delay",
]


def build_flights():
    rows = []
    fid = 0
    for flight_date in DATES:
        for carrier_code, _, _ in CARRIERS:
            for origin, dest, distance in ROUTES:
                fid += 1
                seats = random.choice([150, 180, 200, 240])
                cancelled = 1 if random.random() < 0.03 else 0

                if cancelled:
                    passengers, dep_delay, arr_delay, revenue = 0, 0, 0, 0.0
                else:
                    passengers = int(seats * random.uniform(0.55, 0.98))
                    # 延误分布：多数准点，少数严重延误
                    dep_delay = max(-25, int(random.gauss(12, 35)))
                    arr_delay = dep_delay + random.randint(-10, 15)
                    revenue = round(passengers * random.uniform(90, 420), 2)

                # 延误原因五分类（DOT 口径），只有正延误才归因
                cd = wd = nd = sd = ld = 0
                if dep_delay > 0:
                    r = random.random()
                    if r < 0.35:
                        cd = dep_delay
                    elif r < 0.55:
                        wd = dep_delay
                    elif r < 0.75:
                        nd = dep_delay
                    elif r < 0.80:
                        sd = dep_delay
                    else:
                        ld = dep_delay

                rows.append([
                    f"F{fid:06d}", flight_date, carrier_code, origin, dest,
                    distance, seats, passengers, dep_delay, arr_delay,
                    cancelled, revenue, cd, wd, nd, sd, ld,
                ])
    return rows


def main():
    flights = build_flights()

    flights_csv = DATA_DIR / "raw_flights.csv"
    with open(flights_csv, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(FLIGHT_HEADER)
        writer.writerows(flights)

    carriers_csv = DATA_DIR / "raw_carriers.csv"
    with open(carriers_csv, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["carrier_code", "carrier_name", "country"])
        writer.writerows(CARRIERS)

    con = duckdb.connect(str(BASE / "aviation.duckdb"))
    for table, csv_path in [("raw_flights", flights_csv), ("raw_carriers", carriers_csv)]:
        con.execute(
            f"CREATE OR REPLACE TABLE {table} AS "
            f"SELECT * FROM read_csv_auto('{csv_path.as_posix()}', header=true)"
        )
    print(con.execute("SELECT 'raw_flights' AS t, count(*) AS n FROM raw_flights "
                      "UNION ALL SELECT 'raw_carriers', count(*) FROM raw_carriers").fetchall())
    con.close()


if __name__ == "__main__":
    main()
