{{
    config(
        materialized='incremental',
        unique_key=['location_hk', 'load_date'],
        file_format='parquet'
    )
}}

-- Satellite: Location Metadata
-- Descriptive attributes for locations (timezone, elevation)

with source_data as (
    select
        latitude,
        longitude,
        timezone,
        elevation,
        extracted_at as load_date
    from {{ ref('stg_wave_forecasts') }}
    {% if is_incremental() %}
    where extracted_at > (select max(load_date) from {{ this }})
    {% endif %}
),

hashed as (
    select
        {{ generate_hash_key(['latitude', 'longitude']) }} as location_hk,
        timezone,
        elevation,
        load_date,
        {{ get_record_source('open_meteo_marine') }} as record_source,
        {{ generate_hash_key(['timezone', 'elevation']) }} as hash_diff
    from source_data
)

select
    location_hk,
    timezone,
    elevation,
    load_date,
    record_source,
    hash_diff
from hashed
{% if is_incremental() %}
where not exists (
    select 1
    from {{ this }} existing
    where existing.location_hk = hashed.location_hk
    and existing.hash_diff = hashed.hash_diff
)
{% endif %}
