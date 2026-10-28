{{ config(
    materialized='table',
    database='lake',
    schema='gold',
    alias='fact_redenciones'
) }}

-- Tabla de Hechos de Marketing Directo: Redenciones de Cupones (Gold)
-- Granularidad: Hogar x Cupón x Día de Redención
select
    id_hogar,
    id_cupon,
    id_campana,
    dia,
    1 as cantidad_redenciones,
    _batch_id,
    _ingested_at
from {{ ref('slv_coupon_redempt') }}
