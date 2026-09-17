# Hackathon Starter Module

Small Python example for calling an Azure AI Foundry deployment through the
OpenAI-compatible Responses API, including a function tool call.

## Getting Started

The starter folder contains:
- `main.py` - Runnable example that asks the model an arithmetic question
- `client.py` - Foundry client and Responses API integration
- `tools.py` - `calculate` tool definition and implementation
- `sanity.py` - Direct connectivity check for a configured deployment
- `pyproject.toml` and `uv.lock` - Project metadata and locked dependencies

The starter uses the `.env` file in this folder. Create it once at
`hackathon-rbs2026/starter/.env`.

### Setup Steps for Python

```bash
cd starter
# Create .env and add your Azure OpenAI endpoint, key, and deployment name
uv sync
uv run main.py
```

On Windows, run `setup\install-host.bat` from the repository root first and restart
your computer. Then run the commands above; `uv sync` creates the local environment.

## Configuration

The client loads `.env` from the `starter` directory. It requires these values
from the deployment outputs and Azure AI Foundry resource keys:

```env
AZURE_OPENAI_ENDPOINT=https://foundry-hackathon-rbs2026-<teamname>.services.ai.azure.com/openai/v1
AZURE_OPENAI_API_KEY=your-api-key-here
AZURE_OPENAI_DEPLOYMENT_NAME=your-deployment-name
```

Replace the placeholders with your actual values. The client normalizes the
endpoint to end in `/openai/v1` and removes an `/api/projects/...` suffix if
one is supplied. `AZURE_OPENAI_API_VERSION` is not used by the current client.

## What It Does

Running `uv run main.py`:
1. Loads configuration from `.env`
2. Creates a `FoundryClient` for the configured deployment
3. Sends a French system prompt and arithmetic question to the Responses API
4. Lets the model call `calculate` with an operation and two numbers
5. Sends the tool result back using `previous_response_id`
6. Prints the final answer

You can use the client from another Python module as follows:

```python
from client import FoundryClient

client = FoundryClient()
answer = client.query(
	"You are a helpful assistant.",
	"What is 2 + 2?",
)
print(answer)
```

The `calculate` tool supports `add`, `subtract`, `multiply`, and `divide`.

## Customization

To add another function tool, define its Responses API schema in `tools.py`,
implement it there, and handle its function call in `FoundryClient.query`.
