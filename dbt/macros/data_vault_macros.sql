-- Macro to generate hash keys for Data Vault
{% macro generate_hash_key(columns) %}
    md5(concat_ws('||',
        {% for col in columns %}
            coalesce(cast({{ col }} as varchar), '')
            {% if not loop.last %},{% endif %}
        {% endfor %}
    ))
{% endmacro %}

-- Macro to generate load date
{% macro generate_load_date() %}
    {{ var('load_date', 'current_timestamp()') }}
{% endmacro %}

-- Macro to get record source
{% macro get_record_source(source_name) %}
    '{{ source_name }}'
{% endmacro %}

-- Macro to extract business key columns with null handling
{% macro extract_business_keys(columns) %}
    {% for col in columns %}
        coalesce(cast({{ col }} as varchar), '') as {{ col }}_bk
        {% if not loop.last %},{% endif %}
    {% endfor %}
{% endmacro %}
