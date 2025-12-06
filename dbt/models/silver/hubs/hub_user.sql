{{
    config(
        materialized='incremental',
        unique_key='user_hk',
        file_format='parquet'
    )
}}

-- Hub: User
-- Business Key: email (unique identifier for users)

with source_data as (
    select
        email,
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
        email,
        load_date,
        {{ get_record_source('google_sheets') }} as record_source
    from source_data
)

select distinct
    user_hk,
    email,
    load_date,
    record_source
from hashed
