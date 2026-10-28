"""
Capas de la arquitectura medallón, una por archivo:
    bronze.py -> datos crudos tal como vienen de los CSV (implementada).
    silver.py -> datos limpios y tipados (implementada).
    gold.py   -> modelo dimensional para BI (implementada).
"""

from pipeline.layers.bronze import BronzeLayer
from pipeline.layers.silver import SilverLayer
from pipeline.layers.gold import GoldLayer

__all__ = ["BronzeLayer", "SilverLayer", "GoldLayer"]
