{{
    config(
        materialized='table',
        file_format='parquet'
    )
}}

-- Gold Layer: Location Dimension
-- Denormalized location information for analytics

with latest_location_metadata as (
    select
        location_hk,
        timezone,
        elevation,
        load_date,
        row_number() over (partition by location_hk order by load_date desc) as rn
    from {{ ref('sat_location_metadata') }}
),

location_metadata as (
    select
        location_hk,
        timezone,
        elevation,
        load_date
    from latest_location_metadata
    where rn = 1
)

select
    hub.location_hk,
    hub.latitude,
    hub.longitude,
    meta.timezone,
    meta.elevation,
    -- Calculate a readable location identifier
    concat('Lat: ', cast(round(hub.latitude, 2) as varchar),
           ', Lon: ', cast(round(hub.longitude, 2) as varchar)) as location_label,
    hub.load_date as location_created_at,
    meta.load_date as last_updated_at
from {{ ref('hub_location') }} hub
left join location_metadata meta
    on hub.location_hk = meta.location_hk
