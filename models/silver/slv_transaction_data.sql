{{ config(
    materialized='table',
    database='lake',
    schema='silver',
    alias='transaction_data'
) }}

-- Capa plata: Tipado, Estandarización y Limpieza de Valores (Partes 1, 2 y 3).
select
    trim(cast(household_key as VARCHAR)) as id_hogar,
    trim(cast(basket_id as VARCHAR)) as id_canasta,
    cast(day as INTEGER) as dia,
    trim(cast(product_id as VARCHAR)) as id_producto,
    cast(quantity as BIGINT) as cantidad,
    cast(sales_value as DECIMAL(10, 2)) as valor_venta,
    trim(cast(store_id as VARCHAR)) as id_tienda,
    abs(cast(retail_disc as DECIMAL(10, 2))) as descuento_tienda,
    substr(lpad(trim(trans_time), 4, '0'), 1, 2) || ':' || substr(lpad(trim(trans_time), 4, '0'), 3, 2) as hora_transaccion,
    cast(week_no as INTEGER) as semana,
    abs(cast(coupon_disc as DECIMAL(10, 2))) as descuento_cupon,
    abs(cast(coupon_match_disc as DECIMAL(10, 2))) as descuento_cupon_fabricante,
    case
        when cast(sales_value as DECIMAL(10, 2)) <= 0 or cast(quantity as BIGINT) <= 0 then 'Sí'
        else 'No'
    end as es_muestra_gratis,
    _batch_id,
    _source_file,
    _ingested_at
from {{ ref('transaction_data') }}
