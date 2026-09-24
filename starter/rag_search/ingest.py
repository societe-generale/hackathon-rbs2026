"""Ingest local PDF, Excel, and COBOL copybook files into Azure AI Search."""

import argparse
import hashlib
import json
import os
import re
import urllib.error
import urllib.request
from pathlib import Path
from typing import Iterable, Iterator

import pandas as pd
from dotenv import load_dotenv
from openai import OpenAI
from pypdf import PdfReader


STARTER_DIR = Path(__file__).resolve().parents[1]
load_dotenv(STARTER_DIR / ".env")

CHUNK_SIZE = 1_000
CHUNK_OVERLAP = 150
EMBEDDING_DIMENSIONS = 1_536
SUPPORTED_SUFFIXES = {".pdf", ".xls", ".xlsx", ".cpy"}


def chunks(text: str, size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> Iterator[str]:
    """Split text into overlapping chunks, preferring a word boundary."""
    text = re.sub(r"\s+", " ", text).strip()
    start = 0
    while start < len(text):
        end = min(start + size, len(text))
        if end < len(text):
            boundary = text.rfind(" ", start, end)
            if boundary > start:
                end = boundary
        chunk = text[start:end].strip()
        if chunk:
            yield chunk
        if end == len(text):
            break
        start = max(end - overlap, start + 1)


def extract_pdf(path: Path) -> Iterable[tuple[str, dict[str, object]]]:
    reader = PdfReader(path)
    for page_number, page in enumerate(reader.pages, start=1):
        text = page.extract_text() or ""
        if text.strip():
            yield text, {"page": page_number}


def extract_excel(path: Path) -> Iterable[tuple[str, dict[str, object]]]:
    for sheet_name, frame in pd.read_excel(path, sheet_name=None).items():
        frame = frame.fillna("")
        for row_number, row in enumerate(frame.to_dict(orient="records"), start=2):
            text = " | ".join(f"{column}: {value}" for column, value in row.items() if value != "")
            if text:
                yield text, {"sheet": str(sheet_name), "row_number": row_number}


def extract_copybook(path: Path) -> Iterable[tuple[str, dict[str, object]]]:
    raw = path.read_bytes()
    text = raw.decode("utf-8", errors="replace")
    if text.count("\ufffd") > 10:
        text = raw.decode("cp1252", errors="replace")
    yield text, {}


def extract(path: Path) -> Iterable[tuple[str, dict[str, object]]]:
    if path.suffix.lower() == ".pdf":
        return extract_pdf(path)
    if path.suffix.lower() in {".xls", ".xlsx"}:
        return extract_excel(path)
    if path.suffix.lower() == ".cpy":
        return extract_copybook(path)
    raise ValueError(f"Unsupported file: {path}")


def required_environment(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise ValueError(f"{name} must be set in {STARTER_DIR / '.env'}")
    return value


def foundry_client() -> tuple[OpenAI, str]:
    endpoint = required_environment("AZURE_OPENAI_ENDPOINT").rstrip("/")
    if "/api/projects/" in endpoint:
        endpoint = endpoint.split("/api/projects/", 1)[0]
    if not endpoint.endswith("/openai/v1"):
        endpoint = f"{endpoint}/openai/v1"
    return OpenAI(base_url=endpoint, api_key=required_environment("AZURE_OPENAI_API_KEY")), required_environment(
        "AZURE_OPENAI_EMBEDDING_DEPLOYMENT"
    )


def embed(client: OpenAI, deployment: str, text: str) -> list[float]:
    return client.embeddings.create(model=deployment, input=text).data[0].embedding


def request_search(method: str, url: str, api_key: str, payload: object | None = None) -> dict:
    body = json.dumps(payload).encode("utf-8") if payload is not None else None
    request = urllib.request.Request(
        url,
        data=body,
        method=method,
        headers={"Content-Type": "application/json", "api-key": api_key},
    )
    try:
        with urllib.request.urlopen(request) as response:
            return json.loads(response.read().decode("utf-8")) if response.length != 0 else {}
    except urllib.error.HTTPError as error:
        message = error.read().decode("utf-8")
        raise RuntimeError(f"Azure AI Search {method} {url} failed: {message}") from error


def ensure_index(endpoint: str, api_key: str, index_name: str) -> None:
    url = f"{endpoint.rstrip('/')}/indexes/{index_name}?api-version=2024-07-01"
    index = {
        "name": index_name,
        "fields": [
            {"name": "id", "type": "Edm.String", "key": True, "filterable": True},
            {"name": "content", "type": "Edm.String", "searchable": True},
            {"name": "content_vector", "type": "Collection(Edm.Single)", "searchable": True, "vectorSearchProfile": "vector-profile", "dimensions": EMBEDDING_DIMENSIONS},
            {"name": "source", "type": "Edm.String", "filterable": True, "facetable": True},
            {"name": "source_type", "type": "Edm.String", "filterable": True, "facetable": True},
            {"name": "page", "type": "Edm.Int32", "filterable": True},
            {"name": "sheet", "type": "Edm.String", "filterable": True},
            {"name": "row_number", "type": "Edm.Int32", "filterable": True},
            {"name": "chunk_number", "type": "Edm.Int32", "filterable": True, "sortable": True},
        ],
        "vectorSearch": {
            "algorithms": [{"name": "hnsw", "kind": "hnsw", "hnswParameters": {"metric": "cosine"}}],
            "profiles": [{"name": "vector-profile", "algorithm": "hnsw"}],
        },
    }
    request_search("PUT", url, api_key, index)


def ingest(folder: Path) -> int:
    search_endpoint = required_environment("AZURE_SEARCH_ENDPOINT")
    search_key = required_environment("AZURE_SEARCH_API_KEY")
    index_name = os.getenv("AZURE_SEARCH_INDEX", "rag-chunks")
    client, embedding_deployment = foundry_client()
    ensure_index(search_endpoint, search_key, index_name)

    documents = []
    for path in folder.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in SUPPORTED_SUFFIXES:
            continue
        for text, metadata in extract(path):
            for chunk_number, content in enumerate(chunks(text), start=1):
                identity = f"{path.resolve()}:{metadata}:{chunk_number}"
                documents.append({
                    "@search.action": "mergeOrUpload",
                    "id": hashlib.sha256(identity.encode("utf-8")).hexdigest(),
                    "content": content,
                    "content_vector": embed(client, embedding_deployment, content),
                    "source": path.name,
                    "source_type": path.suffix.lower().lstrip("."),
                    "page": metadata.get("page"),
                    "sheet": metadata.get("sheet"),
                    "row_number": metadata.get("row_number"),
                    "chunk_number": chunk_number,
                })

    if not documents:
        print(f"No supported files found in {folder}")
        return 0

    url = f"{search_endpoint.rstrip('/')}/indexes/{index_name}/docs/index?api-version=2024-07-01"
    for start in range(0, len(documents), 100):
        batch = documents[start:start + 100]
        result = request_search("POST", url, search_key, {"value": batch})
        failures = [item for item in result.get("value", []) if not item.get("status")]
        if failures:
            raise RuntimeError(f"Failed to index documents: {failures}")
        print(f"Indexed {min(start + len(batch), len(documents))}/{len(documents)} chunks")
    return len(documents)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", nargs="?", default="input", type=Path, help="Folder containing source files")
    args = parser.parse_args()
    if not args.folder.is_dir():
        raise ValueError(f"Not a directory: {args.folder}")
    print(f"Finished indexing {ingest(args.folder)} chunks")


if __name__ == "__main__":
    main()