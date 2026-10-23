{% snapshot dim_carrier_scd2 %}

{{
    config(
      target_schema=target.schema ~ '_snapshots',
      unique_key='carrier_code',
      strategy='check',
      check_cols=['carrier_name', 'country']
    )
}}

-- SCD Type 2：航司属性变化时保留历史版本，而不是覆盖
-- dbt 会自动加三列：dbt_scd_id / dbt_valid_from / dbt_valid_to
select
    carrier_code,
    carrier_name,
    country
from {{ ref('stg_carriers') }}

{% endsnapshot %}
