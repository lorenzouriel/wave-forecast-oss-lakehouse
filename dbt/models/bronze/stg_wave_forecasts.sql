{{
    config(
        materialized='view'
    )
}}

-- Staging: Parse wave forecast JSON data from Airbyte
-- This flattens the nested JSON structure into a usable format

with source as (
    select
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _airbyte_generation_id,
        _airbyte_data
    from {{ source('bronze', 'OpenWeather_Waves') }}
),

parsed as (
    select
        _airbyte_raw_id as record_id,
        cast(_airbyte_extracted_at as timestamp) as extracted_at,
        _airbyte_generation_id as generation_id,

        -- Parse top-level fields from JSON
        cast(json_extract_path_text(_airbyte_data, 'latitude') as double) as latitude,
        cast(json_extract_path_text(_airbyte_data, 'longitude') as double) as longitude,
        json_extract_path_text(_airbyte_data, 'timezone') as timezone,
        cast(json_extract_path_text(_airbyte_data, 'elevation') as double) as elevation,

        -- Store the nested hourly data for later unnesting
        json_extract_path_text(_airbyte_data, 'hourly') as hourly_data

    from source
)

select * from parsed
