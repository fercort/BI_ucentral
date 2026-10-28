{{ config(
    materialized='table',
    database='lake',
    schema='silver',
    alias='coupon'
) }}

-- Capa plata: Tipado, Estandarización, Limpieza y Eliminación de Duplicados (Partes 1, 2, 3 y 4).
-- Se eliminan los 5,164 duplicados exactos usando DISTINCT.
select distinct
    trim(cast(coupon_upc as VARCHAR)) as id_cupon,
    trim(cast(product_id as VARCHAR)) as id_producto,
    trim(cast(campaign as VARCHAR)) as id_campana,
    _batch_id,
    _source_file,
    _ingested_at
from {{ ref('coupon') }}
