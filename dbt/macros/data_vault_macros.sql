{% macro generate_hash_key(columns) %}
    md5(concat({% for col in columns %}cast({{ col }} as varchar){% if not loop.last %}, '|', {% endif %}{% endfor %}))
{% endmacro %}

{% macro get_record_source(source_name) %}
    '{{ source_name }}'
{% endmacro %}

{# Override generate_schema_name to map dbt schemas to MinIO buckets #}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        silver
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
