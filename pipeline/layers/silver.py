"""
===============================================================================
 CAPA PLATA: LIMPIEZA, TIPADO Y CALIDAD DE DATOS
===============================================================================

¿Qué es la capa plata?
-----------------------
Es la segunda estación del pipeline medallón. Toma los datos crudos desde
la capa bronce (donde todo era VARCHAR) y les aplica transformaciones para
dejarlos limpios, consistentes y con los tipos de datos correctos para
análisis e inteligencia de negocios.

Reglas aplicadas:
-----------------
1. TIPADO CORRECTO
   - Llaves e IDs a VARCHAR (texto) para evitar pérdida de ceros y operaciones indebidas en BI.
   - Importes monetarios a DECIMAL(10, 2).
   - Métricas enteras (días, semanas, cantidades) a BIGINT / INTEGER.
   - Formateo de tiempos (HH:MM).

2. TRAZABILIDAD
   Se conservan las columnas de auditoría de bronce:
   `_batch_id`, `_source_file` e `_ingested_at`.

3. GOBERNANZA Y AUDITORÍA
   Cada modelo ejecutado registra sus métricas en `audit.ingestion_log`.
"""

from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path
from typing import Callable

import duckdb

from pipeline.config import settings
from pipeline.core.base import Layer, StepResult

CAT = settings.CATALOG_NAME
SILVER = f"{CAT}.{settings.SCHEMA_SILVER}"
INGESTION_LOG = f"{CAT}.{settings.SCHEMA_AUDIT}.ingestion_log"
RUN_RESULTS_PATH = settings.PROJECT_ROOT / "target" / "run_results.json"


class SilverLayer(Layer):
    """Capa plata: gestionada mediante modelos dbt (`models/silver/`)."""

    name = "silver"

    def run(
        self,
        con: duckdb.DuckDBPyConnection,
        batch_id: str,
        tables: list[str] | None = None,
        on_start: Callable[[str], None] | None = None,
        on_step: Callable[[StepResult], None] | None = None,
    ) -> list[StepResult]:

        self._ensure_ingestion_log(con)
        self.log.info("Iniciando capa plata mediante dbt | batch=%s", batch_id)

        # Si se especifican tablas individuales, mapeamos al nombre del modelo con prefijo slv_
        selection = [f"slv_{t}" for t in tables] if tables else ["silver"]
        cmd = [
            "uv", "run", "dbt", "run",
            "--select", *selection,
            "--profiles-dir", ".",
            "--vars", json.dumps({"batch_id": batch_id}),
        ]

        self.log.info("Ejecutando: %s", " ".join(cmd))

        if on_start:
            on_start(", ".join(tables) if tables else "todas las tablas de plata")

        RUN_RESULTS_PATH.unlink(missing_ok=True)

        env = os.environ.copy()
        env["PYTHONPATH"] = str(settings.PROJECT_ROOT)
        process = subprocess.run(cmd, capture_output=True, text=True, cwd=settings.PROJECT_ROOT, env=env)

        if process.returncode != 0:
            self.log.error("dbt run (silver) falló:\n%s\n%s", process.stdout, process.stderr)

        results: list[StepResult] = []

        if not RUN_RESULTS_PATH.exists():
            output = (process.stdout + "\n" + process.stderr).strip()
            error_msg = output[-2000:] or f"dbt terminó con código {process.returncode}"
            target_tables = tables or [s.table_name for s in settings.SOURCES]
            for table_name in target_tables:
                step_result = StepResult(self.name, table_name, "FAILED", 0, 0.0, error_msg)
                results.append(step_result)
                self._log_ingestion(con, batch_id, table_name, f"slv_{table_name}.sql", 0, 0.0, "FAILED", error_msg)
                if on_step:
                    on_step(step_result)
            return results

        with open(RUN_RESULTS_PATH, encoding="utf-8") as f:
            data = json.load(f)

        for result in data.get("results", []):
            model_id = result.get("unique_id", "")
            raw_model_name = model_id.split(".")[-1]
            table_name = raw_model_name.removeprefix("slv_")

            status_dbt = result.get("status")
            seconds = result.get("execution_time") or 0.0
            adapter_response = result.get("adapter_response") or {}
            rows = adapter_response.get("rows_affected") or 0

            status = "SUCCESS" if status_dbt == "success" else "FAILED"
            error_msg = None if status == "SUCCESS" else (result.get("message") or f"dbt status: {status_dbt}")

            if status == "SUCCESS":
                try:
                    rows = con.execute(f"SELECT count(*) FROM {SILVER}.{table_name}").fetchone()[0]
                except Exception:
                    pass

            step_result = StepResult(self.name, table_name, status, rows, seconds, error_msg)
            results.append(step_result)

            self._log_ingestion(con, batch_id, table_name, f"slv_{table_name}.sql", rows, seconds, status, error_msg)

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
