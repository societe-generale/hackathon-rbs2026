"""Test script to verify the CSV Agent works."""

import json
from pathlib import Path
from client import FoundryClient
from simple_csv_agent import CsvAgent


def test_basic_analysis():
    """Run a basic analysis on sample data."""
    print("🧪 Testing CSV Agent\n")

    try:
        # Initialize
        print("1️⃣  Initializing client...")
        client = FoundryClient()
        agent = CsvAgent(client)
        print("   ✓ Client initialized\n")

        # Prepare sample data
        sample_csv = Path(__file__).parent / "sample_data.csv"
        if not sample_csv.exists():
            print(f"   ❌ Sample CSV not found: {sample_csv}")
            return False

        output_dir = Path(__file__).parent / "test_output"
        output_dir.mkdir(exist_ok=True)

        # Run analysis
        print("2️⃣  Running analysis...")

        def progress(step):
            step_names = {
                "profile": "   📊 Profiling CSV",
                "generate": "   ⚙️  Generating code",
                "execute": "   ▶️  Executing code",
                "summarize": "   📝 Summarizing results",
            }
            print(f"{step_names.get(step, step)}...")

        result = agent.analyze(
            csv_path=sample_csv,
            objective="Calculate total sales by region and identify top-selling product",
            output_dir=output_dir,
            on_step=progress,
        )
        print("   ✓ Analysis complete\n")

        # Check results
        print("3️⃣  Verifying results...")

        checks = {
            "✓ Run ID": result.get("run_id") is not None,
            "✓ Code generated": result.get("code_id") is not None,
            "✓ Script saved": Path(result.get("script_path", "")).exists(),
            "✓ Generation time": result.get("generation_seconds", 0) > 0,
            "✓ Execution status": result["execution"]["success"],
        }

        for check, passed in checks.items():
            status = "✅" if passed else "❌"
            print(f"   {status} {check}")

        if not all(checks.values()):
            print("\n   ❌ Some checks failed!")
            print(f"   Error: {result['execution'].get('error', 'unknown')}")
            print(f"   Stderr: {result['execution'].get('stderr', 'none')}")
            return False

        # Display results
        print("\n4️⃣  Results:")
        if result["report"]:
            report = result["report"]
            print(f"   📊 Rows analyzed: {report['row_count']}")
            print(f"   📁 Output: {output_dir / result['run_id']}")

            print(f"\n   📈 Aggregates:")
            for name, value in report["aggregates"].items():
                print(f"      • {name}: {value}")

            print(f"\n   📝 Summary:")
            summary = report["summary"][:200]
            print(f"      {summary}...")

        print("\n✅ All tests passed!")
        return True

    except Exception as e:
        print(f"\n❌ Test failed with error:")
        print(f"   {type(e).__name__}: {e}")
        import traceback

        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = test_basic_analysis()
    exit(0 if success else 1)
