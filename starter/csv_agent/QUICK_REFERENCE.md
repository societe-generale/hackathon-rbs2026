# Simple CSV Agent - Quick Reference

## 30-Second Start

```python
from client import FoundryClient
from simple_csv_agent import CsvAgent

client = FoundryClient()
agent = CsvAgent(client)

result = agent.analyze(
    csv_path="data/sales.csv",
    objective="Total sales by region"
)

print(result["report"]["summary"])
```

## Common Use Cases

### Calculate Totals and Counts
```python
result = agent.analyze(
    csv_path="sales.csv",
    objective="Calculate total revenue, total orders, and average order value"
)
```

### Find Top Items
```python
result = agent.analyze(
    csv_path="orders.csv",
    objective="Find top 5 products by revenue and top 5 by quantity sold"
)
```

### Analyze by Category
```python
result = agent.analyze(
    csv_path="data.csv",
    objective="Calculate average price and count by category"
)
```

### Time-Based Analysis
```python
result = agent.analyze(
    csv_path="transactions.csv",
    objective="Calculate sales by month and identify peak month"
)
```

### Data Quality Check
```python
result = agent.analyze(
    csv_path="data.csv",
    objective="Count missing values, duplicates, and invalid entries"
)
```

## Accessing Results

```python
result = agent.analyze(...)

# File paths and IDs
run_id = result["run_id"]                    # Unique folder name
script_path = result["script_path"]          # Generated Python code
code_id = result["code_id"]                  # Code identifier

# Timing
gen_time = result["generation_seconds"]      # How long code took to generate

# Execution details
exec_success = result["execution"]["success"]
exec_stdout = result["execution"]["stdout"]  # Print output
exec_stderr = result["execution"]["stderr"]  # Error output

# Final report
report = result["report"]
summary = report["summary"]                  # LLM-generated insights
aggregates = report["aggregates"]            # Your calculated values
rows_analyzed = report["row_count"]

# Example: Loop through results
for name, value in aggregates.items():
    print(f"{name}: {value}")
```

## Debugging

```python
# Check if analysis succeeded
if not result["execution"]["success"]:
    print("Failed:", result["execution"]["error"])
    print("Stderr:", result["execution"]["stderr"])

# View generated code
from pathlib import Path
code = Path(result["script_path"]).read_text()
print(code)

# Check input CSV
profile = result.get("profile", {})
print(f"Rows: {profile.get('row_count')}")
print(f"Columns: {profile.get('columns')}")
```

## Tips for Best Results

✅ DO:
- Be specific: "Average sale price by product category" ✓
- Ask for numbers: LLM generates code for aggregates
- Keep it simple: One or two analyses per run
- Use clear column names in your CSV

❌ DON'T:
- Be vague: "analyze the data" ✗
- Ask for full transformations: Use pandas directly instead
- Analyze huge files: Profile loads all data to memory
- Request complex ML: This is for summaries, not ML

## Output File Locations

Generated files saved in: `output/{run_id}/`

```
profile.json       ← CSV structure (columns, types, missing counts)
{code_id}.py       ← Generated Python code
aggregation.csv    ← Raw results from your code (2 columns)
report.json        ← Final report with summary and insights
```

## Expected aggregation.csv Format

Your generated code MUST produce this format:

```csv
aggregate_name,value
total_sales,15000
average_price,125.50
top_region,North
```

## Progress Tracking

Show users what's happening:

```python
def show_progress(step):
    steps = {
        "profile": "Reading CSV structure...",
        "generate": "Writing Python code...",
        "execute": "Running analysis...",
        "summarize": "Writing report..."
    }
    print(steps[step])

result = agent.analyze(
    csv_path="data.csv",
    objective="Calculate totals",
    on_step=show_progress
)
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| File not found | Use full path: `Path("data/file.csv").resolve()` |
| Invalid code generated | Simplify objective, try again |
| CSV format error | Ensure column headers, valid CSV format |
| Timeout | Objective too complex, try simpler query |
| Wrong results | Check generated code: `Path(result['script_path']).read_text()` |

## One-Liners

```python
# Just analyze, no callbacks
result = agent.analyze("sales.csv", "Total revenue")

# With progress
result = agent.analyze("sales.csv", "Total revenue", on_step=lambda x: print(f"Step: {x}"))

# Custom output directory
result = agent.analyze("sales.csv", "Total revenue", output_dir="/tmp/analysis")

# Access just the summary
summary = agent.analyze("sales.csv", "Total")["report"]["summary"]

# Access just the aggregates
aggs = agent.analyze("sales.csv", "Total")["report"]["aggregates"]
```

## Error Messages Explained

```
"CSV file not found"
→ CSV path doesn't exist, check file location

"Invalid Python code generated"
→ LLM produced syntax errors, try simpler objective

"aggregation.csv format error"
→ Generated code didn't create correct CSV format

"Script execution timed out"
→ Analysis taking >60s, simplify objective

"Unknown operation: X"
→ Custom code tried invalid operation, debug generated script
```

## Integration Examples

### With Web Framework
```python
from flask import Flask, request
app = Flask(__name__)

@app.route("/analyze", methods=["POST"])
def analyze_csv():
    csv_path = request.files["file"]
    objective = request.form["objective"]
    result = agent.analyze(csv_path, objective)
    return {"summary": result["report"]["summary"]}
```

### With CLI
```python
import sys
result = agent.analyze(
    csv_path=sys.argv[1],
    objective=sys.argv[2],
    on_step=lambda x: print(f"[{x.upper()}]")
)
print(result["report"]["summary"])
```

### Batch Processing
```python
import glob
for csv_file in glob.glob("data/*.csv"):
    result = agent.analyze(
        csv_path=csv_file,
        objective="Calculate summary statistics"
    )
    print(f"{csv_file}: {result['report']['summary'][:100]}...")
```

---

**That's it!** For more details, see `README.md`
