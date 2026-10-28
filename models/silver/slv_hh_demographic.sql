{{ config(
    materialized='table',
    database='lake',
    schema='silver',
    alias='hh_demographic'
) }}

-- Capa plata: Tipado, Estandarización y Limpieza de Valores (Partes 1, 2 y 3).
select
    trim(cast(household_key as VARCHAR)) as id_hogar,
    trim(cast(classification_1 as VARCHAR)) as rango_edad,
    trim(cast(classification_2 as VARCHAR)) as estado_civil,
    trim(cast(classification_3 as VARCHAR)) as nivel_ingresos,
    case
        when trim(homeowner_desc) in ('Unknown', '') or homeowner_desc is null then 'Sin Información'
        else trim(homeowner_desc)
    end as tipo_vivienda,
    trim(cast(classification_4 as VARCHAR)) as tamano_hogar,
    trim(cast(classification_5 as VARCHAR)) as composicion_hogar,
    case
        when trim(kid_category_desc) in ('None/Unknown', 'Unknown', '') or kid_category_desc is null then 'Sin Hijos / Desconocido'
        else trim(kid_category_desc)
    end as categoria_hijos,
    _batch_id,
    _source_file,
    _ingested_at
from {{ ref('hh_demographic') }}
