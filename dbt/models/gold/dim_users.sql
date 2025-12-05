{{
    config(
        materialized='table',
        file_format='parquet'
    )
}}

-- Gold Layer: User Dimension
-- Denormalized user information for analytics

with latest_user_details as (
    select
        user_hk,
        user_name,
        nickname,
        phone,
        preferred_regions,
        form_submitted_at,
        load_date,
        row_number() over (partition by user_hk order by load_date desc) as rn
    from {{ ref('sat_user_details') }}
),

user_info as (
    select
        user_hk,
        user_name,
        nickname,
        phone,
        preferred_regions,
        form_submitted_at,
        load_date
    from latest_user_details
    where rn = 1
)

select
    hub.user_hk,
    hub.email,
    det.user_name,
    det.nickname,
    det.phone,
    det.preferred_regions,
    -- Parse preferred regions into an array
    split(det.preferred_regions, ', ') as preferred_regions_array,
    det.form_submitted_at,
    hub.load_date as user_created_at,
    det.load_date as last_updated_at
from {{ ref('hub_user') }} hub
inner join user_info det
    on hub.user_hk = det.user_hk
