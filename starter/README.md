# Foundry Starter Module

Simple starter module for connecting to Foundry endpoint in Python.

## Getting Started

The starter folder has the following structure:
- `.env.example` - Configuration template
- Dependencies files (`pyproject.toml`, `uv.lock`)
- `client.py` - Simple client to query Foundry

The starter uses the `.env` file in this folder. Create it once at
`hackathon-rbs2026/starter/.env`.

### Setup Steps for Python

```bash
cd starter
# Edit .env with your Azure OpenAI endpoint, key, and deployment name
uv sync
uv run client.py
```

On Windows, run `setup\install-host.bat` from the repository root first and restart
your computer. Then run the commands above; `uv sync` creates the local environment.

## Configuration

The Python starter uses a `.env` file with these values from the deployment
outputs and Azure AI Foundry resource keys:

```env
AZURE_OPENAI_ENDPOINT=https://foundry-hackathon-rbs2026-<teamname>.services.ai.azure.com/openai/v1
AZURE_OPENAI_API_KEY=your-api-key-here
AZURE_OPENAI_DEPLOYMENT_NAME=chat
AZURE_OPENAI_API_VERSION=2025-04-01-preview
```

Replace the placeholders with your actual values. The endpoint must end in
`/openai/v1`, not `/api/projects/...`.

## What It Does

Each client:
1. Loads configuration from `.env`
2. Takes a system prompt and user query
3. Sends them to the Foundry OpenAI-compatible Responses API
4. Returns the answer

## Customization

You can easily extend each client to:
- Add more methods (e.g., for different types of requests)
- Handle different response formats
- Add error handling specific to your needs
- Integrate with your application
