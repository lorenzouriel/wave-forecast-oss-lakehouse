{{
    config(
        materialized='view'
    )
}}

-- Staging: Parse user surf preferences from Google Sheets

with source as (
    select
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _airbyte_generation_id,
        _airbyte_data
    from {{ source('bronze', 'Respostas_ao_formulario_1') }}
),

parsed as (
    select
        _airbyte_raw_id as record_id,
        cast(_airbyte_extracted_at as timestamp) as extracted_at,
        _airbyte_generation_id as generation_id,

        -- Parse user information from JSON
        json_extract_path_text(_airbyte_data, 'Carimbo de data/hora') as timestamp_str,
        json_extract_path_text(_airbyte_data, 'Qual o seu nome bro?') as user_name,
        json_extract_path_text(_airbyte_data, 'Tem algum apelido massa?') as nickname,
        json_extract_path_text(_airbyte_data, 'Seu e-mail para receber as previsões bro?') as email,
        json_extract_path_text(_airbyte_data, 'Seu número bro?') as phone,
        json_extract_path_text(_airbyte_data, 'Seleciona as regiões em São Paulo que mais curte surfar:') as preferred_regions

    from source
)

select
    record_id,
    extracted_at,
    generation_id,
    user_name,
    nickname,
    email,
    phone,
    preferred_regions,
    -- Parse the timestamp (Brazilian format: DD/MM/YYYY HH:MM:SS)
    try_cast(to_timestamp(timestamp_str, 'DD/MM/YYYY HH:MM:SS') as timestamp) as form_submitted_at
from parsed
