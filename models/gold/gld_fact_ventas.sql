{{ config(
    materialized='table',
    database='lake',
    schema='gold',
    alias='fact_ventas'
) }}

-- Tabla de Hechos de Ventas (Gold)
-- Granularidad: Una línea del tiquete de compra (Hogar x Canasta x Producto)
select
    id_hogar,
    id_producto,
    id_tienda,
    dia,
    id_canasta,
    hora_transaccion,
    semana,
    cantidad,
    valor_venta,
    descuento_tienda,
    descuento_cupon,
    descuento_cupon_fabricante,
    (descuento_tienda + descuento_cupon + descuento_cupon_fabricante) as descuento_total,
    -- Precio unitario pagado según fórmulas de la guía de Dunnhumby:
    -- Evita división por cero cuando cantidad = 0
    case
        when cantidad <= 0 then 0.0
        when descuento_tienda > 0 then
            round((valor_venta + descuento_tienda + descuento_cupon_fabricante) / cantidad, 4)
        else
            round((valor_venta + descuento_cupon_fabricante) / cantidad, 4)
    end as precio_unitario_regular,
    case
        when cantidad <= 0 then 0.0
        else round((valor_venta - descuento_cupon) / cantidad, 4)
    end as precio_unitario_pagado_cliente,
    es_muestra_gratis,
    _batch_id,
    _ingested_at
from {{ ref('slv_transaction_data') }}
