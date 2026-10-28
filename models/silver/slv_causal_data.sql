{{ config(
    materialized='table',
    database='lake',
    schema='silver',
    alias='causal_data'
) }}

-- Capa plata: Tipado, Estandarización y Limpieza de Valores (Partes 1, 2 y 3).
select
    trim(cast(product_id as VARCHAR)) as id_producto,
    trim(cast(store_id as VARCHAR)) as id_tienda,
    cast(week_no as INTEGER) as semana,
    case
        when trim(display) = '0' or display is null or trim(display) = '' then 'Sin Exhibición'
        else trim(display)
    end as ubicacion_exhibicion,
    case
        when trim(mailer) = '0' or mailer is null or trim(mailer) = '' then 'Sin Folleto'
        else trim(mailer)
    end as ubicacion_folleto,
    _batch_id,
    _source_file,
    _ingested_at
from {{ ref('causal_data') }}
