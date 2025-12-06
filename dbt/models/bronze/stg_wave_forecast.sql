{{
    config(
        materialized='table',
        file_format='parquet',
        pre_hook = 'DROP TABLE IF EXISTS "lakehouse-minio".bronze.stg_wave_forecast'
    )
}}

SELECT
    _airbyte_raw_id AS record_id,
    TO_TIMESTAMP(CAST(_airbyte_extracted_at AS BIGINT) / 1000) AS extracted_at,
    _airbyte_generation_id AS generation_id,

    -- Store the whole _airbyte_data for field extraction in silver layer
    -- JSON fields (latitude, longitude, timezone, elevation, hourly) will be parsed in silver
    _airbyte_data AS raw_data

FROM "lakehouse-minio"."bronze"."OpenWeather_Waves"
