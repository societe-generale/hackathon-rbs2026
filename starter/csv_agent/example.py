"""Example: Analyzing a CSV file with the Simple CSV Agent."""

from pathlib import Path
from client import FoundryClient
from simple_csv_agent import CsvAgent


def progress_callback(step: str) -> None:
    """Print progress updates."""
    steps = {
        "profile": "📊 Profiling CSV...",
        "generate": "⚙️  Generating analysis code...",
        "execute": "▶️  Executing code...",
        "summarize": "📝 Generating summary...",
    }
    print(f"\n{steps.get(step, step)}")


def main() -> None:
    # Initialize the LLM client
    client = FoundryClient()

    # Create the CSV agent
    agent = CsvAgent(client)

    # Example: Analyze a CSV file
    csv_file = Path("./data/sales.csv")  # Update this path to your CSV
    objective = "Calculate total sales by region and find the top-performing region"
    output_dir = Path("./analysis_output")

    try:
        print(f"🚀 Starting CSV analysis")
        print(f"   File: {csv_file}")
        print(f"   Objective: {objective}")

        result = agent.analyze(
            csv_path=csv_file,
            objective=objective,
            output_dir=output_dir,
            on_step=progress_callback,
        )

        print("\n✅ Analysis Complete!\n")
        print(f"📁 Output directory: {output_dir / result['run_id']}")
        print(f"💾 Script saved to: {result['script_path']}")
        print(f"⏱️  Generation time: {result['generation_seconds']:.2f}s")

        if result["report"]:
            print(f"\n📊 Results:")
            print(f"   Rows analyzed: {result['report']['row_count']}")
            print(f"\n🔍 Summary:")
            print(f"   {result['report']['summary'][:500]}...")

            print(f"\n📈 Aggregates:")
            for name, value in result["report"]["aggregates"].items():
                print(f"   {name}: {value}")
        else:
            print(f"\n❌ Analysis failed: {result['execution']['error']}")

    except FileNotFoundError as e:
        print(f"❌ Error: {e}")
        print(f"   Make sure {csv_file} exists or update the path in this script")
    except Exception as e:
        print(f"❌ Error: {e}")


if __name__ == "__main__":
    main()
