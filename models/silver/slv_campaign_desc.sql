{{ config(
    materialized='table',
    database='lake',
    schema='silver',
    alias='campaign_desc'
) }}

-- Capa plata: Tipado, Estandarización y Limpieza de Valores (Partes 1, 2 y 3).
select
    trim(cast(campaign as VARCHAR)) as id_campana,
    trim(cast(description as VARCHAR)) as tipo_campana,
    cast(start_day as INTEGER) as dia_inicio,
    cast(end_day as INTEGER) as dia_fin,
    _batch_id,
    _source_file,
    _ingested_at
from {{ ref('campaign_desc') }}
