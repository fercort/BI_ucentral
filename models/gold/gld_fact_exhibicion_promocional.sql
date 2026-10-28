{{ config(
    materialized='table',
    database='lake',
    schema='gold',
    alias='fact_exhibicion_promocional'
) }}

-- Tabla de Hechos de Exhibición Promocional y Publicidad (Gold)
-- Granularidad: Producto x Tienda x Semana
select
    id_producto,
    id_tienda,
    semana,
    ubicacion_exhibicion,
    ubicacion_folleto,
    _batch_id,
    _ingested_at
from {{ ref('slv_causal_data') }}
