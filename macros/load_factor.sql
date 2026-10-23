{#-
    客座率（Load Factor）= 旅客数 / 座位数

    为什么非要写成 macro，而不是每个模型里各写一遍：
    1. 除零保护只写一次，不会某个模型漏掉
    2. 口径变更（比如改用 ASM/RPK 加权）只改这一处，全项目生效
    3. 杜绝「A 报表算 92.3%、B 报表算 91.8%」这种口径漂移
-#}

{% macro load_factor(passengers_col, seats_col) -%}
    case
        when {{ seats_col }} = 0 or {{ seats_col }} is null then null
        else round(100.0 * {{ passengers_col }} / {{ seats_col }}, 2)
    end
{%- endmacro %}
