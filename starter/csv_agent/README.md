# Simple CSV Agent

A beginner-friendly Python CSV analysis agent that uses LLM-generated code to analyze any CSV file.

**No LangGraph. No complexity. Just results.**

## What It Does

1. **Profiles** your CSV (columns, types, missing values)
2. **Generates** Python analysis code based on your objective
3. **Executes** the code safely in a subprocess
4. **Summarizes** results and insights

## Quick Start

```python
from pathlib import Path
from client import FoundryClient
from simple_csv_agent import CsvAgent

# Setup
client = FoundryClient()
agent = CsvAgent(client)

# Analyze
result = agent.analyze(
    csv_path="data/sales.csv",
    objective="Calculate total sales by region",
    output_dir="./output"
)

# Access results
print(result["report"]["summary"])
print(result["report"]["aggregates"])
```

## API Reference

### CsvAgent.analyze()

Main method to analyze a CSV file.

```python
result = agent.analyze(
    csv_path: str | Path,
    objective: str,
    output_dir: str | Path = "./output",
    on_step: callable = None,
)
```

**Parameters:**
- `csv_path`: Path to the CSV file to analyze
- `objective`: What you want to learn (e.g., "Find average order value by customer segment")
- `output_dir`: Where to save generated code and results
- `on_step`: Optional callback for progress tracking, receives: "profile", "generate", "execute", "summarize"

**Returns:**
```python
{
    "run_id": "abc12345",           # Unique run identifier
    "code_id": "def67890",          # Generated code ID
    "script_path": "/path/to/code.py",
    "generation_seconds": 2.34,     # Time to generate code
    "execution": {                  # Execution details
        "success": True,
        "returncode": 0,
        "stdout": "...",
        "stderr": "",
        "error": "",
    },
    "report": {                     # Final results
        "objective": "...",
        "aggregates": {             # Results from your code
            "total_sales": "15000",
            "avg_price": "125.50"
        },
        "summary": "...",           # LLM-generated summary
        "row_count": 1000,
        "column_count": 8,
    }
}
```

## How It Works

### 1. CSV Profiling
Analyzes the CSV structure without loading all data:
- Column names and types (numeric/string)
- Row count
- Missing value counts per column

This information is sent to the LLM to generate better code.

### 2. Code Generation
The LLM generates Python code that:
- Reads from `CSV_INPUT_PATH` environment variable
- Performs analysis based on your objective
- Outputs results to `aggregation.csv` with format:
  ```
  aggregate_name,value
  total_sales,15000
  avg_price,125.50
  ```

### 3. Code Execution
The generated Python script runs in a sandboxed subprocess:
- Timeout: 60 seconds
- Environment variables set for CSV input/output paths
- Output captured for debugging

### 4. Result Summarization
The LLM summarizes the aggregation results and provides insights.

## Customization

### Custom Code Instructions
Modify the LLM prompts in `_get_code_instructions()` and `_get_summary_instructions()`:

```python
agent._get_code_instructions = lambda: """Your custom instructions..."""
```

### Custom CSV Handling
Override the profiling method for special CSV formats:

```python
def custom_profile(self, csv_path):
    # Your custom profiling logic
    return profile_dict

agent._profile_csv = custom_profile
```

### Progress Tracking
Use the `on_step` callback to track progress:

```python
def progress(step):
    print(f"Step: {step}")
    # Log to monitoring system, update UI, etc.

result = agent.analyze(..., on_step=progress)
```

## Generated Code Example

The agent generates code like this for a sales analysis:

```python
import csv
from pathlib import Path
from decimal import Decimal

csv_path = Path(__import__('os').getenv('CSV_INPUT_PATH'))
output_path = Path(__import__('os').getenv('AGGREGATION_OUTPUT_PATH'))

total_sales = 0
region_sales = {}

with open(csv_path, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        try:
            amount = Decimal(row['amount'])
            region = row['region']
            total_sales += amount
            region_sales[region] = region_sales.get(region, 0) + amount
        except:
            pass

top_region = max(region_sales, key=region_sales.get) if region_sales else 'N/A'

with open(output_path, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['aggregate_name', 'value'])
    writer.writerow(['total_sales', str(total_sales)])
    writer.writerow(['top_region', top_region])
```

## Output Structure

After analysis, your output directory contains:

```
output/
├── abc12345/                  # Run ID
│   ├── profile.json          # CSV profiling data
│   ├── abc12345def67890.py   # Generated Python code
│   ├── aggregation.csv       # Raw results from code
│   └── report.json           # Final report with summary
```

## Error Handling

Common issues and solutions:

### "CSV file not found"
Make sure the CSV path is correct:
```python
from pathlib import Path
csv_path = Path("./data/sales.csv").resolve()
print(f"Looking for: {csv_path}")
```

### "Invalid Python code generated"
The LLM generated invalid code. Try:
- More specific objective
- Simpler CSV structure
- Retry (LLM responses can vary)

### "Script execution timed out"
Your analysis is too complex. Try:
- Simpler objective
- Sampling data
- Async processing

### "aggregation.csv format error"
Generated code must output CSV with exactly two columns: `aggregate_name, value`

## Best Practices

1. **Clear Objectives**: "Calculate revenue by quarter and identify top 3 products" works better than "analyze"

2. **Reasonable Results**: Ask for aggregates, not detailed transformations. The CSV agent is for summaries, not full data pipelines.

3. **Error Handling**: Check `result["execution"]["success"]` before accessing results

4. **Progress Tracking**: Use callbacks for user feedback on longer analyses

5. **Resource Limits**: Be mindful of large CSV files (profiling loads all data into memory)

## Comparison with Original Implementation

| Feature | LangGraph Version | Simple Version |
|---------|------------------|----------------|
| Dependencies | LangGraph, complex setup | Just OpenAI client |
| State Machine | Yes, complex graph | Simple linear flow |
| Customization | Requires understanding state | Override methods as needed |
| Beginner Friendly | ❌ No | ✅ Yes |
| Performance | Good | Identical |
| Code Lines | 414 | ~400 (cleaner) |

## Extending the Agent

### Add validation step
```python
class MyCSVAgent(CsvAgent):
    def _validate_aggregation_file(self, path):
        super()._validate_aggregation_file(path)
        # Add custom validation
```

### Add data preprocessing
```python
def custom_analyze(self, csv_path, objective, ...):
    # Preprocess CSV
    cleaned_csv = self._preprocess(csv_path)
    return self.analyze(cleaned_csv, objective, ...)
```

### Add caching
```python
@functools.lru_cache
def _generate_code(self, ...):
    return super()._generate_code(...)
```

## Troubleshooting

Enable debug logging:
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

Check generated code:
```python
result = agent.analyze(...)
script_path = Path(result["script_path"])
print(script_path.read_text())
```

Inspect execution output:
```python
print(result["execution"]["stdout"])
print(result["execution"]["stderr"])
```

## License

Same as parent project
