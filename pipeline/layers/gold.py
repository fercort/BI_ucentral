"""
===============================================================================
 CAPA ORO: MODELADO DIMENSIONAL PARA INTELIGENCIA DE NEGOCIOS (BI)
===============================================================================

¿Qué es la capa oro?
--------------------
Es el nivel superior de la arquitectura medallón. Transforma los datos limpios
de la capa plata en un modelo dimensional estrella (Star Schema) optimizado
para consultas analíticas y consumo directo en herramientas de BI (Power BI).

Estructura:
-----------
- Dimensiones: dim_producto, dim_hogar (2.500 hogares), dim_tiempo, dim_tienda,
  dim_campana, dim_exhibicion, dim_folleto.
- Hechos: fact_ventas, fact_exhibicion_promocional, fact_redenciones.
- Pruebas de Calidad: Validación de claves únicas, no nulas e integridad referencial.
"""

from __future__ import annotations

import json
import os
import subprocess
from typing import Callable

import duckdb

from pipeline.config import settings
from pipeline.core.base import Layer, StepResult

CAT = settings.CATALOG_NAME
GOLD = f"{CAT}.{settings.SCHEMA_GOLD}"
INGESTION_LOG = f"{CAT}.{settings.SCHEMA_AUDIT}.ingestion_log"
RUN_RESULTS_PATH = settings.PROJECT_ROOT / "target" / "run_results.json"


GOLD_TABLE_MAP: dict[str, str] = {
    "product": "gld_dim_producto",
    "hh_demographic": "gld_dim_hogar",
    "campaign_desc": "gld_dim_campana",
    "campaign_table": "gld_dim_campana",
    "causal_data": "gld_fact_exhibicion_promocional",
    "transaction_data": "gld_fact_ventas",
    "coupon_redempt": "gld_fact_redenciones",
    "dim_producto": "gld_dim_producto",
    "dim_hogar": "gld_dim_hogar",
    "dim_tiempo": "gld_dim_tiempo",
    "dim_tienda": "gld_dim_tienda",
    "dim_campana": "gld_dim_campana",
    "dim_exhibicion": "gld_dim_exhibicion",
    "dim_folleto": "gld_dim_folleto",
    "fact_ventas": "gld_fact_ventas",
    "fact_exhibicion_promocional": "gld_fact_exhibicion_promocional",
    "fact_redenciones": "gld_fact_redenciones",
}


class GoldLayer(Layer):
    """Capa oro: gestionada mediante modelos dbt (`models/gold/`)."""

    name = "gold"

    def run(
        self,
        con: duckdb.DuckDBPyConnection,
        batch_id: str,
        tables: list[str] | None = None,
        on_start: Callable[[str], None] | None = None,
        on_step: Callable[[StepResult], None] | None = None,
    ) -> list[StepResult]:

        self._ensure_ingestion_log(con)
        self.log.info("Iniciando capa oro mediante dbt | batch=%s", batch_id)

        if tables:
            selection = list(dict.fromkeys(GOLD_TABLE_MAP.get(t, f"gld_{t}") for t in tables))
        else:
            selection = ["gold"]
        cmd = [
            "uv", "run", "dbt", "run",
            "--select", *selection,
            "--profiles-dir", ".",
            "--vars", json.dumps({"batch_id": batch_id}),
        ]

        self.log.info("Ejecutando: %s", " ".join(cmd))

        if on_start:
            on_start(", ".join(tables) if tables else "todas las tablas de oro")

        RUN_RESULTS_PATH.unlink(missing_ok=True)

        env = os.environ.copy()
        env["PYTHONPATH"] = str(settings.PROJECT_ROOT)
        process = subprocess.run(cmd, capture_output=True, text=True, cwd=settings.PROJECT_ROOT, env=env)

        if process.returncode != 0:
            self.log.error("dbt run (gold) falló:\n%s\n%s", process.stdout, process.stderr)

        results: list[StepResult] = []

        if not RUN_RESULTS_PATH.exists():
            output = (process.stdout + "\n" + process.stderr).strip()
            error_msg = output[-2000:] or f"dbt terminó con código {process.returncode}"
            fallback_tables = tables or ["dim_producto", "dim_hogar", "dim_tiempo", "dim_tienda", "dim_campana", "fact_ventas"]
            for table_name in fallback_tables:
                step_result = StepResult(self.name, table_name, "FAILED", 0, 0.0, error_msg)
                results.append(step_result)
                self._log_ingestion(con, batch_id, table_name, f"gld_{table_name}.sql", 0, 0.0, "FAILED", error_msg)
                if on_step:
                    on_step(step_result)
            return results

        with open(RUN_RESULTS_PATH, encoding="utf-8") as f:
            data = json.load(f)

        for result in data.get("results", []):
            model_id = result.get("unique_id", "")
            raw_model_name = model_id.split(".")[-1]
            table_name = raw_model_name.removeprefix("gld_")

            status_dbt = result.get("status")
            seconds = result.get("execution_time") or 0.0
            adapter_response = result.get("adapter_response") or {}
            rows = adapter_response.get("rows_affected") or 0

            status = "SUCCESS" if status_dbt == "success" else "FAILED"
            error_msg = None if status == "SUCCESS" else (result.get("message") or f"dbt status: {status_dbt}")

            if status == "SUCCESS":
                try:
                    rows = con.execute(f"SELECT count(*) FROM {GOLD}.{table_name}").fetchone()[0]
                except Exception:
                    pass

            step_result = StepResult(self.name, table_name, status, rows, seconds, error_msg)
            results.append(step_result)

            self._log_ingestion(con, batch_id, table_name, f"gld_{table_name}.sql", rows, seconds, status, error_msg)

            if on_step:
                on_step(step_result)

        return results

    @staticmethod
    def _ensure_ingestion_log(con: duckdb.DuckDBPyConnection) -> None:
        con.execute(
            f"""
            CREATE TABLE IF NOT EXISTS {INGESTION_LOG} (
                batch_id      VARCHAR,
                layer         VARCHAR,
                table_name    VARCHAR,
                source_file   VARCHAR,
                rows_loaded   BIGINT,
                duration_sec  DOUBLE,
                status        VARCHAR,
                error_message VARCHAR,
                logged_at     TIMESTAMP WITH TIME ZONE
            )
            """
        )

    def _log_ingestion(
        self,
        con: duckdb.DuckDBPyConnection,
        batch_id: str,
        table_name: str,
        source_file: str,
        rows: int,
        seconds: float,
        status: str,
        error: str | None,
    ) -> None:
        con.execute(
            f"INSERT INTO {INGESTION_LOG} VALUES (?, ?, ?, ?, ?, ?, ?, ?, current_timestamp)",
            [batch_id, self.name, table_name, source_file,
             rows, round(seconds, 3), status, error],
        )
