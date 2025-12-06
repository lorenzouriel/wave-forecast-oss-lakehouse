{{
    config(
        materialized='table',
        file_format='parquet',
        pre_hook = 'DROP TABLE IF EXISTS "lakehouse-minio".bronze.stg_user_preference'
    )
}}

SELECT
    _airbyte_raw_id AS record_id,
    TO_TIMESTAMP(CAST(_airbyte_extracted_at AS BIGINT) / 1000) AS extracted_at,
    _airbyte_generation_id AS generation_id,

    -- Store the whole _airbyte_data for field extraction
    -- Field names with special characters will be parsed in silver layer
    _airbyte_data AS raw_data

FROM "lakehouse-minio"."bronze"."Respostas_ao_formulario_1"
