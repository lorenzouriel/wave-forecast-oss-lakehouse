{{
    config(
        materialized='incremental',
        unique_key=['user_hk', 'load_date'],
        file_format='parquet'
    )
}}

-- Satellite: User Details
-- Descriptive attributes for users (name, phone, preferences)

with source_data as (
    select
        email,
        user_name,
        nickname,
        phone,
        preferred_regions,
        form_submitted_at,
        extracted_at as load_date
    from {{ ref('stg_user_preference') }}
    where email is not null
    {% if is_incremental() %}
    and extracted_at > (select max(load_date) from {{ this }})
    {% endif %}
),

hashed as (
    select
        {{ generate_hash_key(['email']) }} as user_hk,
        user_name,
        nickname,
        phone,
        preferred_regions,
        form_submitted_at,
        load_date,
        {{ get_record_source('google_sheets') }} as record_source,
        {{ generate_hash_key([
            'user_name',
            'nickname',
            'phone',
            'preferred_regions'
        ]) }} as hash_diff
    from source_data
)

select
    user_hk,
    user_name,
    nickname,
    phone,
    preferred_regions,
    form_submitted_at,
    load_date,
    record_source,
    hash_diff
from hashed
{% if is_incremental() %}
where not exists (
    select 1
    from {{ this }} existing
    where existing.user_hk = hashed.user_hk
    and existing.hash_diff = hashed.hash_diff
)
{% endif %}
