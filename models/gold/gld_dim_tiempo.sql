{{ config(
    materialized='table',
    database='lake',
    schema='gold',
    alias='dim_tiempo'
) }}

-- Dimensión de Tiempo Relativo (Gold)
-- Cubre los 711 días del estudio (102 semanas / 2 años)
with dias_unicos as (
    select distinct dia, semana
    from {{ ref('slv_transaction_data') }}
)
select
    dia,
    semana,
    'Año ' || cast(case when dia <= 365 then 1 else 2 end as VARCHAR) as ano_estudio,
    cast(ceil(dia / 30.0) as INTEGER) as mes_aproximado,
    'T' || cast(case when ceil(dia / 90.0) > 8 then 8 else ceil(dia / 90.0) end as VARCHAR) as trimestre_aproximado,
    ((dia - 1) % 7) + 1 as dia_semana_relativo
from dias_unicos
order by dia
