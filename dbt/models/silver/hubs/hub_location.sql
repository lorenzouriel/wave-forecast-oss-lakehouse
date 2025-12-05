{{
    config(
        materialized='incremental',
        unique_key='location_hk',
        file_format='parquet'
    )
}}

-- Hub: Location
-- Business Key: latitude + longitude combination

with source_data as (
    select distinct
        latitude,
        longitude,
        extracted_at as load_date
    from {{ ref('stg_wave_forecasts') }}
    {% if is_incremental() %}
    where extracted_at > (select max(load_date) from {{ this }})
    {% endif %}
),

hashed as (
    select
        {{ generate_hash_key(['latitude', 'longitude']) }} as location_hk,
        latitude,
        longitude,
        load_date,
        {{ get_record_source('open_meteo_marine') }} as record_source
    from source_data
)

select distinct
    location_hk,
    latitude,
    longitude,
    load_date,
    record_source
from hashed
