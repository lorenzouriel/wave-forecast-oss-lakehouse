{{
    config(
        materialized='incremental',
        unique_key=['forecast_hk'],
        file_format='parquet'
    )
}}

-- Satellite: Wave Forecast Hourly
-- Stores hourly wave forecast measurements
-- Note: This stores the entire hourly JSON array per forecast record
-- For detailed hourly breakout, see the gold layer

with source_data as (
    select
        record_id,
        latitude,
        longitude,
        hourly_data,
        extracted_at as load_date
    from {{ ref('stg_wave_forecast') }}
    {% if is_incremental() %}
    where extracted_at > (select max(load_date) from {{ this }})
    {% endif %}
),

hashed as (
    select
        {{ generate_hash_key(['record_id']) }} as forecast_hk,
        {{ generate_hash_key(['latitude', 'longitude']) }} as location_hk,
        hourly_data,
        load_date,
        {{ get_record_source('open_meteo_marine') }} as record_source,
        {{ generate_hash_key(['hourly_data']) }} as hash_diff
    from source_data
)

select
    forecast_hk,
    location_hk,
    hourly_data,
    load_date,
    record_source,
    hash_diff
from hashed
{% if is_incremental() %}
where not exists (
    select 1
    from {{ this }} existing
    where existing.forecast_hk = hashed.forecast_hk
    and existing.hash_diff = hashed.hash_diff
)
{% endif %}
