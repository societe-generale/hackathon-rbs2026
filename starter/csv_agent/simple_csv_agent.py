"""Simple CSV Agent - Analyze any CSV file with LLM-generated Python code."""

import csv
import json
import logging
import os
import subprocess
import sys
import tempfile
import time
import uuid
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)


class CsvAgent:
    """Simple agent to analyze CSV files using LLM-generated Python code."""

    def __init__(self, client):
        """
        Initialize the CSV agent.

        Args:
            client: FoundryClient instance for LLM interactions
        """
        self.client = client
        self.model = client.deployment_name

    def analyze(
        self,
        csv_path: str | Path,
        objective: str,
        output_dir: str | Path = "./output",
        on_step: callable = None,
    ) -> dict[str, Any]:
        """
        Analyze a CSV file with a given objective.

        Args:
            csv_path: Path to the CSV file to analyze
            objective: What you want to learn from the data (e.g., "Calculate total sales by region")
            output_dir: Directory to save generated code and results
            on_step: Optional callback function to track progress (called with: "profile", "generate", "execute", "summarize")

        Returns:
            Dictionary with analysis results including:
            - code_id: Unique ID for the generated code
            - script_path: Path to the saved Python script
            - execution: Execution results (success, stdout, stderr)
            - report: Final analysis report with insights
        """
        csv_path = Path(csv_path)
        output_dir = Path(output_dir)

        if not csv_path.exists():
            raise FileNotFoundError(f"CSV file not found: {csv_path}")

        if not objective.strip():
            raise ValueError("Analysis objective cannot be empty")

        output_dir.mkdir(parents=True, exist_ok=True)
        run_id = uuid.uuid4().hex[:8]
        run_dir = output_dir / run_id
        run_dir.mkdir(parents=True, exist_ok=True)

        logger.info(f"Starting CSV analysis: {csv_path}")
        logger.info(f"Output directory: {run_dir}")

        # Step 1: Profile the CSV
        if on_step:
            on_step("profile")
        profile = self._profile_csv(csv_path)
        (run_dir / "profile.json").write_text(
            json.dumps(profile, indent=2), encoding="utf-8"
        )

        # Step 2: Generate analysis code
        if on_step:
            on_step("generate")
        code_id, code, generation_time = self._generate_code(csv_path, profile, objective)
        script_path = run_dir / f"{code_id}.py"
        script_path.write_text(code, encoding="utf-8")
        logger.info(f"Generated code saved to: {script_path}")

        # Step 3: Execute the code
        if on_step:
            on_step("execute")
        execution_result = self._execute_code(script_path, csv_path, run_dir)

        if not execution_result["success"]:
            logger.error(f"Code execution failed: {execution_result['error']}")
            return {
                "code_id": code_id,
                "script_path": str(script_path),
                "generation_seconds": generation_time,
                "execution": execution_result,
                "report": None,
            }

        # Step 4: Summarize results
        if on_step:
            on_step("summarize")
        aggregation_path = run_dir / "aggregation.csv"
        report = self._summarize_results(aggregation_path, objective, profile)
        (run_dir / "report.json").write_text(
            json.dumps(report, indent=2), encoding="utf-8"
        )

        logger.info(f"Analysis complete: {run_dir}")

        return {
            "run_id": run_id,
            "code_id": code_id,
            "script_path": str(script_path),
            "generation_seconds": generation_time,
            "execution": execution_result,
            "report": report,
        }

    def _profile_csv(self, csv_path: Path) -> dict[str, Any]:
        """
        Profile a CSV file without loading all data into memory.
        Returns column names, types, and missing counts.
        Auto-detects delimiter (comma or semicolon).
        """
        logger.info(f"Profiling CSV: {csv_path}")

        # Auto-detect delimiter
        with open(csv_path, "r", encoding="utf-8-sig", newline="") as f:
            first_line = f.readline()
            delimiter = ";" if ";" in first_line else ","
            f.seek(0)

            reader = csv.DictReader(f, delimiter=delimiter)
            if not reader.fieldnames:
                raise ValueError("CSV file has no columns")

            fieldnames = reader.fieldnames
            missing_counts = {name: 0 for name in fieldnames}
            is_numeric = {name: True for name in fieldnames}
            row_count = 0

            for row in reader:
                row_count += 1
                for field, value in row.items():
                    if field is None:  # Skip None fields from malformed rows
                        continue
                    if not value or not str(value).strip():
                        missing_counts[field] += 1
                    elif is_numeric[field]:
                        try:
                            Decimal(str(value).strip())
                        except (InvalidOperation, ValueError):
                            is_numeric[field] = False

        profile = {
            "row_count": row_count,
            "columns": [
                {
                    "name": name,
                    "type": "numeric" if is_numeric[name] else "string",
                    "missing_count": missing_counts[name],
                }
                for name in fieldnames
            ],
        }

        logger.info(f"Profiled: {row_count} rows, {len(fieldnames)} columns")
        return profile

    def _generate_code(
        self, csv_path: Path, profile: dict[str, Any], objective: str
    ) -> tuple[str, str, float]:
        """
        Generate Python code to analyze the CSV using the LLM.
        Returns: (code_id, code_string, generation_time_seconds)
        """
        started = time.perf_counter()

        prompt = self._build_code_generation_prompt(csv_path, profile, objective)

        logger.info("Requesting code generation from LLM")
        response = self.client.client.responses.create(
            model=self.model,
            instructions=self._get_code_instructions(),
            input=prompt,
            max_output_tokens=4000,
        )

        code = self._extract_python_code(response.output_text)
        code_id = uuid.uuid4().hex[:16]
        generation_time = time.perf_counter() - started

        logger.info(f"Code generated in {generation_time:.2f}s (ID: {code_id})")
        return code_id, code, generation_time

    def _build_code_generation_prompt(
        self, csv_path: Path, profile: dict[str, Any], objective: str
    ) -> str:
        """Build the prompt for code generation."""
        columns_info = "\n".join(
            f"  - {col['name']} ({col['type']}, {col['missing_count']} missing)"
            for col in profile["columns"]
        )

        return f"""CSV Analysis Task

CSV Path: {csv_path.name}
Rows: {profile['row_count']}

Columns:
{columns_info}

Objective: {objective}

Write Python code that:
1. Reads the CSV from environment variable CSV_INPUT_PATH
2. Analyzes the data to address the objective
3. Outputs results as aggregation.csv with columns: aggregate_name, value

The code should be self-contained and handle edge cases gracefully."""

    def _get_code_instructions(self) -> str:
        """Get system instructions for code generation."""
        return """You are a Python data analyst. Generate clean, robust Python code for CSV analysis.

Requirements:
- Code must read CSV from CSV_INPUT_PATH environment variable
- The CSV file may use semicolon (;) or comma (,) as delimiter - detect and handle both
- For pandas: use delimiter='auto' is not available, so try pd.read_csv(...) first, then retry with sep=';' if needed
- Or use Python's csv module which auto-detects delimiters
- Code must write results to aggregation.csv with columns: aggregate_name, value
- Handle missing values and errors gracefully
- Output aggregation.csv in the current working directory
- Aggregate results should be numeric values (one result per row)
- Note: Amounts may be negative (expenses) - convert to positive when needed"""

    def _extract_python_code(self, response_text: str) -> str:
        """Extract Python code from LLM response (handles markdown code blocks)."""
        import re

        # Try to extract from markdown code block first
        match = re.search(r"```python\n(.*?)\n```", response_text, re.DOTALL)
        if match:
            code = match.group(1).strip()
        else:
            match = re.search(r"```\n(.*?)\n```", response_text, re.DOTALL)
            if match:
                code = match.group(1).strip()
            else:
                code = response_text.strip()

        # Validate basic Python syntax
        try:
            compile(code, "<string>", "exec")
        except SyntaxError as e:
            raise ValueError(f"Invalid Python code generated: {e}")

        return code

    def _execute_code(
        self, script_path: Path, csv_path: Path, run_dir: Path
    ) -> dict[str, Any]:
        """
        Execute the generated Python script.
        Returns execution result with stdout, stderr, and success status.
        """
        logger.info(f"Executing script: {script_path}")

        aggregation_path = run_dir / "aggregation.csv"
        env = os.environ.copy()
        env["CSV_INPUT_PATH"] = str(csv_path)
        env["AGGREGATION_OUTPUT_PATH"] = str(aggregation_path)

        try:
            result = subprocess.run(
                [sys.executable, str(script_path)],
                cwd=str(run_dir),
                env=env,
                capture_output=True,
                text=True,
                timeout=60,
            )

            success = result.returncode == 0
            error = ""

            if not success:
                error = result.stderr or f"Script exited with code {result.returncode}"
            elif not aggregation_path.exists():
                error = "Script did not produce aggregation.csv"
                success = False
            else:
                # Validate aggregation file format
                try:
                    self._validate_aggregation_file(aggregation_path)
                except ValueError as e:
                    error = str(e)
                    success = False

            logger.info(f"Execution {'succeeded' if success else 'failed'}")

            return {
                "success": success,
                "returncode": result.returncode,
                "stdout": result.stdout[-2000:] if result.stdout else "",
                "stderr": result.stderr[-2000:] if result.stderr else "",
                "error": error,
                "aggregation_path": str(aggregation_path) if success else None,
            }

        except subprocess.TimeoutExpired:
            logger.error("Script execution timed out")
            return {
                "success": False,
                "error": "Script execution timed out after 60 seconds",
            }
        except Exception as e:
            logger.error(f"Execution error: {e}")
            return {"success": False, "error": str(e)}

    def _validate_aggregation_file(self, path: Path) -> None:
        """Validate that aggregation.csv has the correct format."""
        if not path.exists():
            raise ValueError("aggregation.csv not found")

        with open(path, "r", encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f)
            if reader.fieldnames != ["aggregate_name", "value"]:
                raise ValueError(
                    f"aggregation.csv must have columns: aggregate_name, value. "
                    f"Found: {reader.fieldnames}"
                )

            row_count = 0
            for row in reader:
                row_count += 1
                if row.get("aggregate_name") is None or row.get("value") is None:
                    raise ValueError(f"Row {row_count} missing required columns")

                # Validate value is numeric
                try:
                    Decimal(str(row["value"]).strip())
                except (InvalidOperation, ValueError):
                    raise ValueError(
                        f"Row {row_count}: '{row['value']}' is not a valid number"
                    )

            if row_count == 0:
                raise ValueError("aggregation.csv has no data rows")

    def _summarize_results(
        self, aggregation_path: Path, objective: str, profile: dict[str, Any]
    ) -> dict[str, Any]:
        """
        Summarize the aggregation results using the LLM.
        Returns a report with insights.
        """
        logger.info("Generating summary report")

        # Read aggregation results
        aggregates = {}
        with open(aggregation_path, "r", encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f)
            for row in reader:
                aggregates[row["aggregate_name"]] = row["value"]

        # Build summary prompt
        summary_prompt = self._build_summary_prompt(objective, aggregates, profile)

        response = self.client.client.responses.create(
            model=self.model,
            instructions=self._get_summary_instructions(),
            input=summary_prompt,
            max_output_tokens=2000,
        )

        report = {
            "objective": objective,
            "aggregates": aggregates,
            "summary": response.output_text,
            "column_count": len(profile["columns"]),
            "row_count": profile["row_count"],
        }

        logger.info("Summary report generated")
        return report

    def _build_summary_prompt(
        self, objective: str, aggregates: dict[str, str], profile: dict[str, Any]
    ) -> str:
        """Build the prompt for result summarization."""
        aggregates_str = "\n".join(
            f"  {name}: {value}" for name, value in aggregates.items()
        )

        return f"""Analysis Results Summary

Objective: {objective}

Aggregated Results:
{aggregates_str}

Data Profile:
- Total rows: {profile['row_count']}
- Total columns: {len(profile['columns'])}

Please provide a clear, concise summary of the analysis results and key insights."""

    def _get_summary_instructions(self) -> str:
        """Get system instructions for result summarization."""
        return """You are a data analyst. Summarize CSV analysis results clearly and concisely.
Focus on answering the analysis objective using the provided aggregates.
Highlight key insights and notable findings."""
