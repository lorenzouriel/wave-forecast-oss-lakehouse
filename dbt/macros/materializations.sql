{% materialization table, adapter='dremio' %}
  {%- set identifier = model['alias'] -%}
  {%- set target_relation = api.Relation.create(
      identifier=identifier,
      schema=schema,
      database=database,
      type='table') -%}
  {%- set existing_relation = load_cached_relation(target_relation) -%}
  {%- set tmp_relation = make_temp_relation(target_relation) -%}

  {{ run_hooks(pre_hooks) }}

  -- Drop existing table if it exists
  {% if existing_relation is not none %}
    {{ adapter.drop_relation(existing_relation) }}
  {% endif %}

  -- Build the model
  {% call statement('main') -%}
    {{ create_table_as(False, target_relation, sql) }}
  {%- endcall %}

  {{ run_hooks(post_hooks) }}

  {% do persist_docs(target_relation, model) %}

  {{ return({'relations': [target_relation]}) }}

{% endmaterialization %}
