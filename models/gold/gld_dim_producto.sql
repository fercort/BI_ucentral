{{ config(
    materialized='table',
    database='lake',
    schema='gold',
    alias='dim_producto'
) }}

-- Dimensión de Productos (Gold)
select
    id_producto,
    departamento,
    categoria,
    subcategoria,
    marca,
    id_fabricante,
    tamano_producto
from {{ ref('slv_product') }}
