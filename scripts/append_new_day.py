"""
模拟新一天的数据到达：生成 2024-01-09 的航班数据并追加进 raw_flights。

作用：让增量模型有"新数据"可处理，从而观察 is_incremental() 那段 where 生效。
对应真实场景：T+1 的源系统把昨天的数据推过来。

用法：python scripts/append_new_day.py [YYYY-MM-DD]
"""

import csv
import random
import sys
from pathlib import Path

import duckdb

BASE = Path(__file__).resolve().parent.parent
DB = BASE / "aviation.duckdb"

CARRIERS = ["AA", "DL", "UA", "WN"]
ROUTES = [("DFW", "LAX", 1235), ("ATL", "JFK", 760), ("ORD", "DEN", 888), ("SEA", "SFO", 679)]

HEADER = [
    "flight_id", "flight_date", "carrier_code", "origin", "dest", "distance",
    "seats", "passengers", "dep_delay", "arr_delay", "cancelled", "revenue",
    "carrier_delay", "weather_delay", "nas_delay", "security_delay",
    "late_aircraft_delay",
]


def build_rows(flight_date: str, start_id: int):
    random.seed(hash(flight_date) % 10000)
    rows, fid = [], start_id
    for carrier_code in CARRIERS:
        for origin, dest, distance in ROUTES:
            fid += 1
            seats = random.choice([150, 180, 200, 240])
            cancelled = 1 if random.random() < 0.05 else 0

            if cancelled:
                passengers, dep_delay, arr_delay, revenue = 0, 0, 0, 0.0
            else:
                passengers = int(seats * random.uniform(0.55, 0.98))
                dep_delay = max(-25, int(random.gauss(12, 35)))
                arr_delay = dep_delay + random.randint(-10, 15)
                revenue = round(passengers * random.uniform(90, 420), 2)

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
    flight_date = sys.argv[1] if len(sys.argv) > 1 else "2024-01-09"

    con = duckdb.connect(str(DB))

    existing = con.execute("SELECT count(*) FROM raw_flights").fetchone()[0]
    already = con.execute(
        "SELECT count(*) FROM raw_flights WHERE flight_date = ?", [flight_date]
    ).fetchone()[0]
    if already:
        print(f"{flight_date} 的数据已存在（{already} 行），跳过")
        con.close()
        return

    rows = build_rows(flight_date, existing)

    # 先落一份 CSV 留痕，再插入：真实场景里这一步由上游系统完成
    csv_path = BASE / "data" / f"raw_flights_{flight_date}.csv"
    csv_path.parent.mkdir(exist_ok=True)
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(HEADER)
        w.writerows(rows)

    con.execute(
        f"INSERT INTO raw_flights SELECT * FROM read_csv_auto('{csv_path.as_posix()}', header=true)"
    )

    total = con.execute("SELECT count(*) FROM raw_flights").fetchone()[0]
    max_date = con.execute("SELECT max(flight_date) FROM raw_flights").fetchone()[0]
    print(f"已追加 {len(rows)} 行 {flight_date} 的航班数据")
    print(f"raw_flights 现有 {total} 行，最新日期 {max_date}")
    con.close()


if __name__ == "__main__":
    main()
