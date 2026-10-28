{{ config(
    materialized='table',
    database='lake',
    schema='gold',
    alias='dim_hogar'
) }}

-- Dimensión de Hogares / Clientes (Gold)
-- Incluye la totalidad de los 2.500 hogares del estudio.
-- Los 1.699 hogares que no reportaron datos demográficos se completan con 'Sin Información'.
with todos_hogares as (
    select distinct id_hogar from {{ ref('slv_transaction_data') }}
)
select
    h.id_hogar,
    coalesce(d.rango_edad, 'Sin Información') as rango_edad,
    coalesce(d.estado_civil, 'Sin Información') as estado_civil,
    coalesce(d.nivel_ingresos, 'Sin Información') as nivel_ingresos,
    coalesce(d.tipo_vivienda, 'Sin Información') as tipo_vivienda,
    coalesce(d.tamano_hogar, 'Sin Información') as tamano_hogar,
    coalesce(d.composicion_hogar, 'Sin Información') as composicion_hogar,
    coalesce(d.categoria_hijos, 'Sin Información') as categoria_hijos,
    case when d.id_hogar is not null then 'Sí' else 'No' end as tiene_demografia
from todos_hogares h
left join {{ ref('slv_hh_demographic') }} d on h.id_hogar = d.id_hogar
