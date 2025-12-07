{{
    config(
        materialized='incremental',
        unique_key='location_hk',
        file_format='parquet'
    )
}}

WITH parsed_json AS (
    SELECT
        CONVERT_FROM(CAST(raw_data AS VARCHAR), 'JSON') AS json_obj,
        extracted_at
    FROM {{ ref('stg_wave_forecast') }}
    {% if is_incremental() %}
    WHERE extracted_at > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}
),

source_data AS (
    SELECT DISTINCT
        -- Use Dremio's JSON_VALUE or CAST to extract JSON fields
        CAST(JSON_VALUE(json_obj, '$.latitude') AS DOUBLE) AS latitude,
        CAST(JSON_VALUE(json_obj, '$.longitude') AS DOUBLE) AS longitude,
        extracted_at AS load_date
    FROM parsed_json
    WHERE JSON_VALUE(json_obj, '$.latitude') IS NOT NULL
      AND JSON_VALUE(json_obj, '$.longitude') IS NOT NULL
),

hashed AS (
    SELECT
        {{ generate_hash_key(['latitude', 'longitude']) }} AS location_hk,
        latitude,
        longitude,
        load_date,
        {{ get_record_source('open_meteo_marine') }} AS record_source
    FROM source_data
)

SELECT DISTINCT
    location_hk,
    latitude,
    longitude,
    load_date,
    record_source
FROM hashed