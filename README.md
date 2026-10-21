# aviation-dbt

数据开发转型作品集 · 航空客运数仓（dbt Core + DuckDB 本地栈）

## 这是什么

用 dbt Core 把一个极简航空客运数仓从贴源层做到汇总层，全流程可版本化、可测试、可复现。
生产环境对应关系：DuckDB → Redshift / Snowflake，其余代码完全一致。

## 环境要求

- Python 3.12（本机：`D:\Python312`）
- dbt-core 1.12.x + dbt-duckdb 1.11.x（已装在 `.venv` 内）

## 怎么跑起来

```bash
cd /d/aviation-dbt
.venv\Scripts\activate

# 1) 生成样例数据（模拟 EL：把 CSV 载入 DuckDB）
python scripts/gen_sample_data.py

# 2) 构建模型 + 跑测试
dbt build --profiles-dir .

# 3) 生成文档与血缘图（会打开浏览器）
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .
```

预期结果：`PASS=15 WARN=0 ERROR=0`，`dev_marts.mart_carrier_daily` 32 行（8 天 × 4 航司）。

## 已知问题：中文 Windows 下编码报错

**症状**：

```
UnicodeDecodeError: 'gbk' codec can't decode byte 0x8c in position 88: illegal multibyte sequence
  File "...\dbt\parser\manifest.py", line 1210, in build_manifest_state_check
    project_hashes[name] = FileHash.from_contents(fp.read())
```

**原因**：dbt 在计算项目文件哈希时用 `open(fp)` 打开文件且不指定编码，Python 于是使用系统默认编码。中文 Windows 的默认编码是 **GBK**，而本项目文件是 **UTF-8**，文件里的中文注释一读就崩。这不是项目配置错误，与 dbt 版本无关。

**修复**（开启 Python 的 UTF-8 模式，一次性永久生效）：

```bash
setx PYTHONUTF8 1
```

然后**关掉终端重开**，再跑 `dbt build`。只想临时生效的话用 `set PYTHONUTF8=1`（仅当前窗口）。

验证：

```bash
python -c "import locale; print(locale.getpreferredencoding(False))"
```

必须打印 `utf-8`。若仍为 `cp936` / `gbk`，说明环境变量没生效（没重开终端）。

## 项目结构

```
aviation-dbt/
├── dbt_project.yml          # 项目配置：模型路径、分层物化策略
├── profiles.yml             # 连接配置（dev / ci 两套 target）
├── models/
│   ├── staging/             # 清洗层，对应 ODS -> DWD
│   │   ├── stg_flights.sql
│   │   ├── stg_carriers.sql
│   │   └── schema.yml       # sources 声明 + 列级测试
│   └── marts/               # 汇总层，对应 DWS
│       ├── mart_carrier_daily.sql
│       └── schema.yml
├── tests/
│       └── assert_grain_unique.sql   # 粒度唯一性断言
├── scripts/
│       └── gen_sample_data.py        # 样例数据生成（EL 环节，在 dbt 之外）
└── data/                    # 原始 CSV（已 gitignore）
```

## 分层约定

| 层 | 目录 | 物化 | 职责 | 禁止 |
|---|---|---|---|---|
| ODS | `main.raw_*` | 外部写入 | 原样落地 | dbt 不写、不改 |
| DWD | `models/staging` | view | 改名、改类型、行级清洗 | 不做聚合、不做业务判断 |
| DWS | `models/marts` | table | 按主题汇总 | 不存比率（分子分母另存） |

物理 schema：`dev_staging` / `dev_marts`（由 `dbt_project.yml` 的 `+schema` 控制，避免全挤在 `dev` 里）。

## 当前进度

- [x] W3：项目骨架、source/ref、分层落地、可复现构建
- [ ] W4：snapshot 实现 SCD2、GitHub Actions CI、cloned 可跑通
- [ ] W5：指标体系（RPK/ASK/LF/OTP 等 18 项指标字典）
