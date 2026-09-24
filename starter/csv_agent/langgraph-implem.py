"""LangGraph CSV agent: generate once, execute, and summarize."""

import json
import logging
import uuid
from pathlib import Path
from typing import Any, Callable, TypedDict

from langchain_core.tools import StructuredTool
from langgraph.graph import END, START, StateGraph

from client import FoundryClient
from config import settings
from csv_tools import CsvTools
from utils import import_csv

logger = logging.getLogger(__name__)


class CsvState(TypedDict, total=False):
    objective: str
    profile: dict[str, Any]
    code_id: str
    code: str
    script_path: str
    generation_seconds: float
    execution: dict[str, Any]
    error: str
    aggregation_path: str
    report_path: str
    report: dict[str, Any]


class CsvAnalysisAgent:
    def __init__(self, *, foundry_client: FoundryClient | None = None):
        self.foundry = foundry_client or FoundryClient()
        self.model = self.foundry.deployment_name

    @staticmethod
    def _prompt(state: CsvState) -> str:
        request: dict[str, Any] = {
            "objective": state["objective"],
            "profile": state["profile"],
            "task": settings.prompts.aggregation_task,
        }
        return json.dumps(request, ensure_ascii=False)

    def _make_graph(self, tools: CsvTools, on_step: Callable[[str], None] | None = None):
        write_tool = StructuredTool.from_function(tools.write_python_code)
        execute_tool = StructuredTool.from_function(tools.execute_python_code)
        summary_tool = StructuredTool.from_function(tools.summarize)
        self.write_tool = write_tool
        self.execute_tool = execute_tool
        self.summary_tool = summary_tool

        def write(state: CsvState) -> dict[str, Any]:
            if on_step:
                on_step("write")
            logger.info("Generating CSV analysis code")
            try:
                generated = write_tool.invoke({"prompt": self._prompt(state)})
                logger.info("Generated CSV analysis code (code_id=%s)", generated["code_id"])
                return {**generated, "error": ""}
            except (SyntaxError, ValueError) as exc:
                logger.warning("Code generation failed: %s", exc)
                return {"code_id": "", "error": str(exc)}

        def execute(state: CsvState) -> dict[str, Any]:
            if on_step:
                on_step("execute")
            logger.info("Executing CSV analysis code (code_id=%s)", state["code_id"])
            result = execute_tool.invoke({"code_id": state["code_id"]})
            logger.info("CSV analysis execution finished (success=%s, returncode=%s)", result["success"], result["returncode"])
            return {
                "execution": result,
                "aggregation_path": result["aggregation_path"] or "",
                "error": result["error"],
            }

        def after_write(state: CsvState) -> str:
            if state.get("code_id"):
                return "execute"
            return "failed"

        def after_execute(state: CsvState) -> str:
            if state["execution"]["success"]:
                return "summary"
            return "failed"

        def summarize(state: CsvState) -> dict[str, Any]:
            if on_step:
                on_step("summary")
            logger.info("Generating CSV analysis summary")
            return summary_tool.invoke({
                "aggregation_path": state["aggregation_path"],
                "objective": state["objective"],
            })

        graph = StateGraph(CsvState)
        graph.add_node("write", write)
        graph.add_node("execute", execute)
        graph.add_node("summary", summarize)
        graph.add_edge(START, "write")
        graph.add_conditional_edges("write", after_write, {"execute": "execute", "failed": END})
        graph.add_conditional_edges("execute", after_execute, {"summary": "summary", "failed": END})
        graph.add_edge("summary", END)
        return graph.compile()

    def run(self, csv_path: Path, objective: str, output_dir: Path,
            on_step: Callable[[str], None] | None = None) -> dict[str, Any]:
        logger.info("Starting CSV analysis for %s", csv_path)
        source = import_csv(csv_path)
        if not objective.strip():
            raise ValueError("Analysis objective cannot be empty")
        run_dir = Path(output_dir).resolve() / uuid.uuid4().hex
        run_dir.mkdir(parents=True, exist_ok=False)
        logger.info("Created CSV analysis run directory: %s", run_dir)
        tools = CsvTools(self.foundry, run_dir, source)
        if on_step:
            on_step("profile")
        profile = tools.profile()
        graph = self._make_graph(tools, on_step=on_step)
        state = graph.invoke({"objective": objective, "profile": profile})
        if "report" not in state:
            logger.error("CSV analysis failed after one generation")
            raise RuntimeError(f"CSV analysis failed after one generation: {state.get('error', 'unknown error')}")
        logger.info("CSV analysis completed: %s", state["report_path"])
        return {
            "run_dir": str(run_dir),
            "code_id": state["code_id"],
            "script_path": state["script_path"],
            "generation_seconds": state["generation_seconds"],
            "aggregation_path": state["aggregation_path"],
            "report_path": state["report_path"],
            "report": state["report"],
            "execution": state["execution"],
        }


"""Foundry code generation and local execution tools for CSV analysis."""

import ast
import csv
import json
import logging
import os
import re
import shutil
import subprocess
import sys
import time
import uuid
from decimal import Decimal, InvalidOperation
from functools import wraps
from pathlib import Path
from typing import Any, Callable, TypeVar

from pydantic import BaseModel, ConfigDict, field_validator

from client import FoundryClient
from config import settings
from utils import import_csv, read_csv_rows

logger = logging.getLogger(__name__)

MAX_OUTPUT_CHARS = 8000
EXECUTION_TIMEOUT_SECONDS = 60
FOUNDRY_REQUEST_TIMEOUT_SECONDS = 90

class SummaryItem(BaseModel):
    model_config = ConfigDict(strict=True, extra="forbid")

    Insight: str
    Signal_in_the_data: str
    details: str

    @field_validator("Insight", "Signal_in_the_data")
    @classmethod
    def require_text(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("Summary fields must not be blank")
        return value.strip()


class SummaryOutput(BaseModel):
    model_config = ConfigDict(strict=True, extra="forbid")

    items: list[SummaryItem]

_Result = TypeVar("_Result")


def validate_code_id(method: Callable[..., _Result]) -> Callable[..., _Result]:
    """Reject code IDs that are not lowercase UUID hex strings."""
    @wraps(method)
    def wrapper(self: "CsvTools", code_id: str, *args: Any, **kwargs: Any) -> _Result:
        if not isinstance(code_id, str) or not re.fullmatch(r"[0-9a-f]{32}", code_id):
            raise ValueError("Invalid code_id")
        return method(self, code_id, *args, **kwargs)

    return wrapper


def require_saved_code(method: Callable[..., _Result]) -> Callable[..., _Result]:
    """Require the program to exist in this run's program directory."""
    @wraps(method)
    def wrapper(self: "CsvTools", code_id: str, *args: Any, **kwargs: Any) -> _Result:
        if not (self.program_dir / f"{code_id}.py").is_file():
            raise ValueError("Unknown code_id for this run")
        return method(self, code_id, *args, **kwargs)

    return wrapper


def _plain_code(text: str) -> str:
    text = text.strip()
    match = re.fullmatch(r"```(?:python)?\s*\n(.*?)\n```", text, flags=re.DOTALL | re.IGNORECASE)
    code = (match.group(1) if match else text).strip() + "\n"
    if not code.strip() or len(code.encode("utf-8")) > settings.code.max_code_bytes:
        raise ValueError("Generated Python is empty or exceeds the code size limit")
    ast.parse(code)
    return code


def _parse_json_text(text: str) -> dict[str, Any]:
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*\n|\n```$", "", text, flags=re.IGNORECASE)
    result = json.loads(text)
    if not isinstance(result, dict):
        raise ValueError("Expected a JSON object")
    return result


def read_aggregates(path: Path) -> dict[str, str]:
    if path.stat().st_size > settings.code.max_aggregation_bytes:
        raise ValueError("Aggregation CSV exceeds 1 MiB")
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames != ["aggregate_name", "value"]:
            raise ValueError("Aggregation CSV must have exactly aggregate_name,value columns")
        values: dict[str, str] = {}
        for row in reader:
            if len(values) >= settings.code.max_aggregates:
                raise ValueError("Aggregation CSV exceeds 1000 results")
            if None in row or row["aggregate_name"] is None or row["value"] is None:
                raise ValueError("Aggregation CSV rows must have exactly two fields")
            name, value = row["aggregate_name"], row["value"]
            if not name or name != name.strip() or name in values:
                raise ValueError("Aggregate names must be nonempty and unique")
            try:
                number = Decimal(value)
            except (InvalidOperation, TypeError) as exc:
                raise ValueError("Aggregate values must be numeric") from exc
            if not number.is_finite():
                raise ValueError("Aggregate values must be finite")
            values[name] = value
    if not values:
        raise ValueError("Aggregation CSV has no results")
    return values


class CsvTools:
    """Tools bound to one run so a code ID can only resolve within that run."""

    def __init__(self, foundry: FoundryClient, run_dir: Path, csv_path: Path):
        self.code_model = getattr(foundry, "code_deployment_name", None) or foundry.deployment_name
        self.summary_model = foundry.deployment_name
        self.client = foundry.client
        self.run_dir = Path(run_dir).resolve()
        source = import_csv(csv_path)
        self.run_dir.mkdir(parents=True, exist_ok=True)
        # Generated programs consume a predictable UTF-8, comma-separated file.
        # Bank exports commonly arrive as cp1252 with a semicolon delimiter.
        normalized_path = self.run_dir / "input_normalized.csv"
        rows = read_csv_rows(source)
        with normalized_path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=list(rows[0]) if rows else [],
                                    lineterminator="\n")
            if rows:
                writer.writeheader()
                writer.writerows(rows)
        self.csv_path = normalized_path
        self.program_dir = self.run_dir / "programs"
        self.program_dir.mkdir(parents=True, exist_ok=True)

    def profile(self) -> dict[str, Any]:
        """Profile column types and missing counts locally without sending CSV rows."""
        logger.info("Profiling CSV: %s", self.csv_path)
        with self.csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
            reader = csv.reader(handle, delimiter=";")
            names = next(reader, [])
            if not names or any(not name for name in names) or len(names) != len(set(names)):
                raise ValueError("CSV must have nonempty, unique column names")
            missing, numeric, count = [0] * len(names), [True] * len(names), 0
            for row in reader:
                if len(row) != len(names):
                    raise ValueError("CSV rows must match the header width")
                count += 1
                for index, value in enumerate(row):
                    if not value.strip():
                        missing[index] += 1
                    else:
                        try:
                            Decimal(value)
                        except InvalidOperation:
                            numeric[index] = False
        profile = {"row_count": count, "columns": [
            {"name": name, "dtype": "number" if numeric[index] else "string",
             "missing_count": missing[index]}
            for index, name in enumerate(names)
        ]}
        (self.run_dir / "profile.json").write_text(
            json.dumps(profile, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        logger.info("CSV profile complete: %d rows, %d columns", count, len(names))
        return profile

    def write_python_code(self, prompt: str) -> dict[str, Any]:
        """Generate Python with a dedicated Foundry call and save it by code ID."""
        started = time.perf_counter()
        logger.info("Requesting CSV analysis code from Foundry")
        response = self.client.responses.create(
            model=self.code_model, store=False, instructions=settings.prompts.code_instructions,
            input=prompt, timeout=settings.code.generation_timeout_seconds,
            max_output_tokens=settings.code.max_generation_tokens,
            reasoning={"effort": settings.code.generation_reasoning_effort},
        )
        code = _plain_code(response.output_text)
        code_id = uuid.uuid4().hex
        script = self.program_dir / f"{code_id}.py"
        with script.open("x", encoding="utf-8", newline="\n") as handle:
            handle.write(code)
        logger.info("Saved generated code: %s", script)
        return {"code_id": code_id, "code": code, "script_path": str(script),
                "generation_seconds": time.perf_counter() - started}

    @validate_code_id
    @require_saved_code
    def execute_python_code(self, code_id: str) -> dict[str, Any]:
        """Run the exact saved program on this computer and collect its outputs."""
        script = self.program_dir / f"{code_id}.py"

        work_dir = self.run_dir / "artifacts" / code_id / uuid.uuid4().hex
        work_dir.mkdir(parents=True, exist_ok=False)
        logger.info("Running generated code in %s", work_dir)
        aggregation = work_dir / "aggregation.csv"
        environment = os.environ.copy()
        for key in tuple(environment):
            if key.startswith(("AZURE_OPENAI_", "OPENAI_")):
                environment.pop(key)
        environment.update({
            "CSV_INPUT_PATH": str(self.csv_path),
            "AGGREGATION_OUTPUT_PATH": str(aggregation),
        })
        try:
            completed = subprocess.run(
                [sys.executable, "-I", str(script)], cwd=work_dir, env=environment,
                capture_output=True, text=True, errors="replace",
                timeout=EXECUTION_TIMEOUT_SECONDS, check=False,
            )
            stdout, stderr = completed.stdout[-MAX_OUTPUT_CHARS:], completed.stderr[-MAX_OUTPUT_CHARS:]
            returncode = completed.returncode
            error = (stderr or f"Python exited with status {returncode}") if returncode else ""
        except subprocess.TimeoutExpired as exc:
            logger.warning("Generated code timed out after %d seconds (code_id=%s)", EXECUTION_TIMEOUT_SECONDS, code_id)
            stdout = exc.stdout or b""
            stderr = exc.stderr or b""
            stdout = stdout.decode("utf-8", "replace") if isinstance(stdout, bytes) else stdout
            stderr = stderr.decode("utf-8", "replace") if isinstance(stderr, bytes) else stderr
            stdout, stderr = stdout[-MAX_OUTPUT_CHARS:], stderr[-MAX_OUTPUT_CHARS:]
            returncode, error = None, f"Execution timed out after {EXECUTION_TIMEOUT_SECONDS} seconds"
        files = sorted(str(path) for path in work_dir.rglob("*") if path.is_file())
        if not error:
            try:
                read_aggregates(aggregation)
            except (OSError, ValueError, UnicodeError) as exc:
                error = f"Invalid or missing aggregation.csv: {exc}"
        if not error:
            shutil.copyfile(aggregation, self.run_dir / "aggregation.csv")
            logger.info("Validated aggregation CSV for code_id=%s", code_id)
        else:
            logger.warning("Generated code failed validation or execution (code_id=%s, returncode=%s)", code_id, returncode)
        return {
            "code_id": code_id, "returncode": returncode, "stdout": stdout,
            "stderr": stderr, "generated_files": files,
            "aggregation_path": str(self.run_dir / "aggregation.csv") if not error else None,
            "success": not error, "error": error[-MAX_OUTPUT_CHARS:],
        }

    def summarize(self, aggregation_path: str, objective: str) -> dict[str, Any]:
        """Write the final answer using only validated aggregate values."""
        selected = read_aggregates(Path(aggregation_path))
        logger.info("Requesting summary for %d validated aggregates", len(selected))
        response = self.client.responses.parse(
            model=self.summary_model, store=False,
            instructions=settings.prompts.summary_system_prompt,
            input=json.dumps({
                "objective": objective, "aggregates": selected
            }),
            text_format=SummaryOutput,
            timeout=FOUNDRY_REQUEST_TIMEOUT_SECONDS,
        )
        if response.output_parsed is None:
            raise ValueError("Analysis report has no structured output")
        items = response.output_parsed.items
        report = {
            "selected_aggregates": selected,
            "items": [item.model_dump() for item in items],
        }
        report_path = self.run_dir / "report.json"
        report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        logger.info("Saved CSV analysis report: %s", report_path)
        return {"report_path": str(report_path), "report": report}