{{ config(
    materialized='table',
    database='lake',
    schema='silver',
    alias='campaign_table'
) }}

-- Capa plata: Tipado, Estandarización y Limpieza de Valores (Partes 1, 2 y 3).
select
    trim(cast(household_key as VARCHAR)) as id_hogar,
    trim(cast(campaign as VARCHAR)) as id_campana,
    trim(cast(description as VARCHAR)) as tipo_campana,
    _batch_id,
    _source_file,
    _ingested_at
from {{ ref('campaign_table') }}
