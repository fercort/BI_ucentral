{{ config(
    materialized='table',
    database='lake',
    schema='gold',
    alias='dim_folleto'
) }}

-- Dimensión Ubicación en Folleto Semanal (Gold)
-- Decodificación oficial del catálogo Dunnhumby (Pág. 6)
select * from (
    values
        ('Sin Folleto', 'Not on ad', 'Sin Folleto Promocional'),
        ('0', 'Not on ad', 'Sin Folleto Promocional'),
        ('A', 'Interior page feature', 'Destacado en Página Interior'),
        ('C', 'Interior page line item', 'Línea de Artículo en Página Interior'),
        ('D', 'Front page feature', 'Portada Principal del Folleto'),
        ('F', 'Back page feature', 'Contraportada del Folleto'),
        ('H', 'Wrap front feature', 'Portada de Envoltorio Promocional'),
        ('J', 'Wrap interior coupon', 'Cupón Interior de Envoltorio'),
        ('L', 'Wrap back feature', 'Contraportada de Envoltorio'),
        ('P', 'Interior page coupon', 'Cupón en Página Interior'),
        ('X', 'Free on interior page', 'Artículo Gratis en Página Interior'),
        ('Z', 'Free on front/back page/wrap', 'Artículo Gratis en Portada/Contraportada')
) as t(codigo_folleto, descripcion_en, descripcion_es)
