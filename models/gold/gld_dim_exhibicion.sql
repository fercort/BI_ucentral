{{ config(
    materialized='table',
    database='lake',
    schema='gold',
    alias='dim_exhibicion'
) }}

-- Dimensión Tipo de Exhibición en Tienda (Gold)
-- Decodificación oficial del catálogo Dunnhumby (Pág. 6)
select * from (
    values
        ('Sin Exhibición', 'Not on Display', 'Sin Exhibición', 0),
        ('0', 'Not on Display', 'Sin Exhibición', 0),
        ('1', 'Store Front', 'Frente de Tienda', 1),
        ('2', 'Store Rear', 'Parte Trasera de Tienda', 2),
        ('3', 'Front End Cap', 'Cabecera Frontal de Pasillo', 3),
        ('4', 'Mid-Aisle End Cap', 'Cabecera Media de Pasillo', 4),
        ('5', 'Rear End Cap', 'Cabecera Trasera de Pasillo', 5),
        ('6', 'Side-Aisle End Cap', 'Cabecera Lateral de Pasillo', 6),
        ('7', 'In-Aisle', 'Dentro del Pasillo', 7),
        ('9', 'Secondary Location Display', 'Ubicación Secundaria', 9),
        ('A', 'In-Shelf', 'En Anaquel Especial', 10)
) as t(codigo_exhibicion, descripcion_en, descripcion_es, jerarquia_prioridad)
