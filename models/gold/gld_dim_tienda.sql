{{ config(
    materialized='table',
    database='lake',
    schema='gold',
    alias='dim_tienda'
) }}

-- Dimensión Tiendas (Gold)
with tiendas_unificadas as (
    select distinct id_tienda from {{ ref('slv_transaction_data') }}
    union
    select distinct id_tienda from {{ ref('slv_causal_data') }}
)
select
    id_tienda,
    'Tienda ' || id_tienda as nombre_tienda
from tiendas_unificadas
order by id_tienda
