{{ config(
    materialized='table',
    database='lake',
    schema='silver',
    alias='coupon_redempt'
) }}

-- Capa plata: Tipado, Estandarización y Limpieza de Valores (Partes 1, 2 y 3).
select
    trim(cast(household_key as VARCHAR)) as id_hogar,
    cast(day as INTEGER) as dia,
    trim(cast(coupon_upc as VARCHAR)) as id_cupon,
    trim(cast(campaign as VARCHAR)) as id_campana,
    _batch_id,
    _source_file,
    _ingested_at
from {{ ref('coupon_redempt') }}
