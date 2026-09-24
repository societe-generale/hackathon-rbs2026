# RAG Search

This module turns local documents into searchable text for a simple RAG application.
It stores the searchable chunks and vectors in Azure AI Search; the original files stay on your computer.

## What it does

1. `ingest.py` reads PDF, Excel (`.xls` and `.xlsx`), and COBOL copybook (`.cpy`) files.
2. It splits the extracted text into small overlapping chunks, creates an embedding for each chunk with Azure AI Foundry, and writes them to Azure AI Search.
3. `query.py` embeds a question, asks Azure AI Search for the most relevant chunks using keyword and vector search, and prints the chunks with their source information.

## Before you start

Run these commands from the `starter` directory. Put these values in `starter/.env`:

```env
AZURE_OPENAI_ENDPOINT=https://<your-foundry-resource>.services.ai.azure.com/openai/v1
AZURE_OPENAI_API_KEY=<your-foundry-key>
AZURE_OPENAI_EMBEDDING_DEPLOYMENT=embed
AZURE_SEARCH_ENDPOINT=https://<your-search-service>.search.windows.net
AZURE_SEARCH_API_KEY=<your-search-admin-key>
AZURE_SEARCH_INDEX=rag-chunks
```

`AZURE_OPENAI_EMBEDDING_DEPLOYMENT` should name an embedding deployment such as `text-embedding-3-small`. Its output needs 1,536 dimensions, matching the index definition.

## Ingest files

Create an `input` folder under `starter`, then copy your documents into it:

```bash
mkdir input
uv run -m rag_search.ingest input
```

The first ingestion creates the Azure AI Search index. Later runs update existing chunks and add new ones. The script records each chunk's file name, PDF page, or Excel sheet and row so results can cite their source.

## Search the documents

Ask a question after ingestion completes:

```bash
uv run -m rag_search.query "What is the payment process?"
uv run -m rag_search.query --top 8 "Show the revenue forecast"
```

To use the retrieved content in your chat code, import `search`:

```python
from rag_search.query import search

chunks = search("What is the payment process?")
context = "\n\n".join(result["content"] for result in chunks)
```

Pass `context` to your chat model with instructions to answer only from this supplied material and cite the listed sources.