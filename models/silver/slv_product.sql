{{ config(
    materialized='table',
    database='lake',
    schema='silver',
    alias='product'
) }}

-- Capa plata: Tipado, Estandarización y Limpieza de Valores (Partes 1, 2 y 3).
select
    trim(cast(product_id as VARCHAR)) as id_producto,
    trim(cast(manufacturer as VARCHAR)) as id_fabricante,
    case
        when trim(department) = '' or department is null then 'Sin Información'
        else trim(department)
    end as departamento,
    trim(cast(brand as VARCHAR)) as marca,
    case
        when trim(commodity_desc) = '' or commodity_desc is null or trim(commodity_desc) = 'UNKNOWN' then 'Sin Información'
        else trim(commodity_desc)
    end as categoria,
    case
        when trim(sub_commodity_desc) = '' or sub_commodity_desc is null or trim(sub_commodity_desc) = 'UNKNOWN' then 'Sin Información'
        else trim(sub_commodity_desc)
    end as subcategoria,
    case
        when trim(curr_size_of_product) = '' or curr_size_of_product is null then 'Sin Información'
        else trim(curr_size_of_product)
    end as tamano_producto,
    _batch_id,
    _source_file,
    _ingested_at
from {{ ref('product') }}
