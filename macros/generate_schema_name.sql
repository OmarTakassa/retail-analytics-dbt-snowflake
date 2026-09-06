/*
    MACRO: generate_schema_name
    
    Purpose: Control which Snowflake schema each model lands in.
    
    By default, dbt appends your target schema as a prefix.
    This macro overrides that behavior so models land in clean schema names:
    - staging models → STAGING schema
    - marts models → MARTS schema
    - snapshots → SNAPSHOTS schema
    
    Without this macro: models would land in "dev_staging", "dev_marts" etc.
    With this macro: models land cleanly in "STAGING", "MARTS" etc.
*/

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}
