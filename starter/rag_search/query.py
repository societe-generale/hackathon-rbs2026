"""Retrieve source chunks from the Azure AI Search index created by ingest.py."""

import argparse
import json
import os

from .ingest import embed, foundry_client, request_search, required_environment


def search(question: str, top: int = 5) -> list[dict]:
    """Run a hybrid keyword and vector query and return RAG-ready chunks."""
    endpoint = required_environment("AZURE_SEARCH_ENDPOINT")
    api_key = required_environment("AZURE_SEARCH_API_KEY")
    index_name = os.getenv("AZURE_SEARCH_INDEX", "rag-chunks")
    client, embedding_deployment = foundry_client()
    question_vector = embed(client, embedding_deployment, question)

    url = f"{endpoint.rstrip('/')}/indexes/{index_name}/docs/search?api-version=2024-07-01"
    payload = {
        "search": question,
        "top": top,
        "select": "content,source,source_type,page,sheet,row_number,chunk_number",
        "vectorQueries": [{
            "kind": "vector",
            "vector": question_vector,
            "fields": "content_vector",
            "k": top,
        }],
    }
    return request_search("POST", url, api_key, payload).get("value", [])


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("question", help="Question or search phrase")
    parser.add_argument("--top", type=int, default=5, help="Maximum number of chunks to return")
    args = parser.parse_args()
    if args.top < 1:
        raise ValueError("--top must be at least 1")

    results = search(args.question, args.top)
    if not results:
        print("No matching chunks found.")
        return

    for number, result in enumerate(results, start=1):
        source = result["source"]
        if result.get("page") is not None:
            source += f" p. {result['page']}"
        if result.get("sheet"):
            source += f" / {result['sheet']}"
        if result.get("row_number") is not None:
            source += f" / row {result['row_number']}"
        print(f"[{number}] {source}\n{result['content']}\n")

    print(json.dumps(results, indent=2, ensure_ascii=True))


if __name__ == "__main__":
    main()