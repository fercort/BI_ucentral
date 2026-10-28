{{ config(
    materialized='table',
    database='lake',
    schema='gold',
    alias='dim_campana'
) }}

-- Dimensión de Campañas de Marketing (Gold)
select
    id_campana,
    tipo_campana,
    dia_inicio,
    dia_fin,
    (dia_fin - dia_inicio + 1) as duracion_dias
from {{ ref('slv_campaign_desc') }}
order by cast(id_campana as INTEGER)
