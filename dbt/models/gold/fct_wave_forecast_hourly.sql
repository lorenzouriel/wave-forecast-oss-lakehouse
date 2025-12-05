{{
    config(
        materialized='table',
        file_format='parquet'
    )
}}

-- Gold Layer: Wave Forecast Hourly Facts
-- Unnests the hourly arrays into individual rows for analysis
-- This creates one row per hour per forecast location

with forecast_base as (
    select
        sat.forecast_hk,
        sat.location_hk,
        sat.hourly_data,
        sat.load_date,
        hub.latitude,
        hub.longitude,
        meta.timezone,
        meta.elevation
    from {{ ref('sat_wave_forecast_hourly') }} sat
    inner join {{ ref('hub_location') }} hub
        on sat.location_hk = hub.location_hk
    left join {{ ref('sat_location_metadata') }} meta
        on sat.location_hk = meta.location_hk
),

-- Parse the time array
time_unnested as (
    select
        forecast_hk,
        location_hk,
        latitude,
        longitude,
        timezone,
        elevation,
        load_date,
        hourly_data,
        cast(json_array_get(json_extract(hourly_data, '$.time'), idx) as varchar) as forecast_time,
        idx as hour_index
    from forecast_base
    cross join unnest(sequence(0, 167)) as t(idx)  -- 7 days * 24 hours = 168 hours (0-167)
    where json_array_length(json_extract(hourly_data, '$.time')) > idx
),

-- Parse all wave metrics
wave_metrics as (
    select
        forecast_hk,
        location_hk,
        latitude,
        longitude,
        timezone,
        elevation,
        load_date,
        hour_index,
        try_cast(regexp_replace(forecast_time, '"', '') as timestamp) as forecast_timestamp,

        -- Wave metrics
        try_cast(json_array_get(json_extract(hourly_data, '$.wave_height'), hour_index) as double) as wave_height,
        try_cast(json_array_get(json_extract(hourly_data, '$.wave_direction'), hour_index) as double) as wave_direction,
        try_cast(json_array_get(json_extract(hourly_data, '$.wave_period'), hour_index) as double) as wave_period,

        -- Swell metrics
        try_cast(json_array_get(json_extract(hourly_data, '$.swell_wave_height'), hour_index) as double) as swell_wave_height,
        try_cast(json_array_get(json_extract(hourly_data, '$.swell_wave_direction'), hour_index) as double) as swell_wave_direction,
        try_cast(json_array_get(json_extract(hourly_data, '$.swell_wave_period'), hour_index) as double) as swell_wave_period,

        -- Wind wave metrics
        try_cast(json_array_get(json_extract(hourly_data, '$.wind_wave_height'), hour_index) as double) as wind_wave_height,
        try_cast(json_array_get(json_extract(hourly_data, '$.wind_wave_direction'), hour_index) as double) as wind_wave_direction,
        try_cast(json_array_get(json_extract(hourly_data, '$.wind_wave_period'), hour_index) as double) as wind_wave_period,

        -- Secondary swell
        try_cast(json_array_get(json_extract(hourly_data, '$.secondary_swell_wave_height'), hour_index) as double) as secondary_swell_wave_height,
        try_cast(json_array_get(json_extract(hourly_data, '$.secondary_swell_wave_direction'), hour_index) as double) as secondary_swell_wave_direction,
        try_cast(json_array_get(json_extract(hourly_data, '$.secondary_swell_wave_period'), hour_index) as double) as secondary_swell_wave_period,

        -- Ocean conditions
        try_cast(json_array_get(json_extract(hourly_data, '$.sea_level_height_msl'), hour_index) as double) as sea_level_height,
        try_cast(json_array_get(json_extract(hourly_data, '$.sea_surface_temperature'), hour_index) as double) as sea_surface_temperature,
        try_cast(json_array_get(json_extract(hourly_data, '$.ocean_current_velocity'), hour_index) as double) as ocean_current_velocity,
        try_cast(json_array_get(json_extract(hourly_data, '$.ocean_current_direction'), hour_index) as double) as ocean_current_direction

    from time_unnested
)

select
    {{ generate_hash_key(['forecast_hk', 'hour_index']) }} as wave_forecast_hourly_pk,
    forecast_hk,
    location_hk,
    latitude,
    longitude,
    timezone,
    elevation,
    forecast_timestamp,
    hour_index,
    wave_height,
    wave_direction,
    wave_period,
    swell_wave_height,
    swell_wave_direction,
    swell_wave_period,
    wind_wave_height,
    wind_wave_direction,
    wind_wave_period,
    secondary_swell_wave_height,
    secondary_swell_wave_direction,
    secondary_swell_wave_period,
    sea_level_height,
    sea_surface_temperature,
    ocean_current_velocity,
    ocean_current_direction,
    load_date as forecast_loaded_at
from wave_metrics
where forecast_timestamp is not null
