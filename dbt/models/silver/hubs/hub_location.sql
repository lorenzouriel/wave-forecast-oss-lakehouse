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
    FROM {{ ref('stg_wave_forecasts') }}
    {% if is_incremental() %}
    WHERE extracted_at > (SELECT MAX(load_date) FROM {{ this }})
    {% endif %}
),

source_data AS (
    SELECT DISTINCT
        CAST(json_obj['latitude'] AS DOUBLE) AS latitude,
        CAST(json_obj['longitude'] AS DOUBLE) AS longitude,
        extracted_at AS load_date
    FROM parsed_json
    WHERE json_obj['latitude'] IS NOT NULL
      AND json_obj['longitude'] IS NOT NULL
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
