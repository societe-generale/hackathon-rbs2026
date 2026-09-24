"""Run CSV Agent on client_data.csv - Better analysis with clearer objective."""

import sys
from pathlib import Path

# Add parent directory to path to import modules
parent_dir = Path(__file__).parent.parent
sys.path.insert(0, str(parent_dir))
sys.path.insert(0, str(Path(__file__).parent))

# Import from parent starter directory
from client import FoundryClient
from simple_csv_agent import CsvAgent


def progress_callback(step: str) -> None:
    """Show progress updates."""
    steps = {
        "profile": "[PROFILE] Profiling transaction data...",
        "generate": "[GENERATE] Generating analysis code...",
        "execute": "[EXECUTE] Executing transaction analysis...",
        "summarize": "[SUMMARIZE] Generating financial insights...",
    }
    print(f"\n{steps.get(step, step)}")


def main():
    print("=" * 60)
    print("CLIENT BANKING DATA ANALYSIS - RUN 2")
    print("=" * 60)

    try:
        # Initialize
        print("\n[INIT] Initializing client...")
        client = FoundryClient()
        agent = CsvAgent(client)

        # Prepare paths
        csv_file = Path(__file__).parent / "sample_data.csv"
        output_dir = Path(__file__).parent / "analysis_output"

        if not csv_file.exists():
            print(f"[ERROR] File not found: {csv_file}")
            return

        # More specific objective focusing on AMOUNT column
        objective = """Analyze the banking transactions CSV file which uses semicolon delimiter.
The AMOUNT column contains transaction amounts (negative for expenses).

You should always answer in French sentences.
Provide:
1. Period of data in the source file
2. Number of transactions (count of rows)
3. Average transaction amount
4. Most common transaction TYPE value
5. Top 5 suppliers by total spending using SUPPLIER_CLEAN column
6. Top 5 category spending with average amount per category
"""

        print(f"\n[DATA] File: {csv_file.name}")
        print(f"[OBJECTIVE]\n{objective}")

        # Run analysis
        print("\n" + "=" * 60)
        print("RUNNING ANALYSIS...")
        print("=" * 60)

        result = agent.analyze(
            csv_path=csv_file,
            objective=objective,
            output_dir=output_dir,
            on_step=progress_callback,
        )

        # Display results
        print("\n" + "=" * 60)
        print("ANALYSIS COMPLETE")
        print("=" * 60)

        if result["execution"]["success"]:
            report = result["report"]

            print(f"\n[OUTPUT] Directory: {output_dir / result['run_id']}")
            print(f"[CODE] Script: {result['script_path']}")
            print(f"[TIME] Generation: {result['generation_seconds']:.2f}s")

            print(f"\n[DATA SUMMARY]:")
            print(f"   Rows analyzed: {report['row_count']:,}")
            print(f"   Columns: {report['column_count']}")

            print(f"\n[RESULTS]:")
            for name, value in report["aggregates"].items():
                print(f"   {name}: {value}")

            print(f"\n[INSIGHTS]:")
            summary = report["summary"]
            lines = summary.split("\n")
            for line in lines[:15]:  # First 15 lines
                if line.strip():
                    print(f"   {line}")

            print(f"\n[SUCCESS] Full report saved to:")
            print(f"   {output_dir / result['run_id'] / 'report.json'}")

        else:
            print(f"\n[FAILED] Analysis failed!")
            print(f"   Error: {result['execution']['error']}")
            print(f"   Stderr: {result['execution']['stderr']}")
            print(f"   Generated code: {result['script_path']}")

            # Show generated code for debugging
            if Path(result['script_path']).exists():
                print(f"\n[DEBUG] Generated code:")
                print("-" * 60)
                print(Path(result['script_path']).read_text()[:800])
                print("-" * 60)

    except FileNotFoundError as e:
        print(f"\n[ERROR] {e}")
    except Exception as e:
        print(f"\n[ERROR] {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
