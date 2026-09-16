# Foundry Starter Module

Simple starter modules for connecting to Foundry endpoint in Python, Java, and JavaScript.

## Getting Started

Each language folder has the same structure:
- `.env.example` - Configuration template
- Language-specific dependencies/build files
- `client.py` / `FoundryClient.java` / `client.js` - Simple client to query Foundry

All three starters share one `.env` file in the repository root. Create it once
at `hackathon-rbs2026/.env`; do not create separate `.env` files in the language
folders.

### Setup Steps for Each Language

#### Python
```bash
cd python
# Edit ..\..\.env with your Azure OpenAI endpoint, key, and deployment name
uv sync
uv run client.py
```

On Windows, run `setup\install-host.bat` from the repository root first and restart
your computer. Then run the commands above; `uv sync` creates the local environment.

#### Java
```bash
cd java
# Edit ..\..\.env with your Azure OpenAI endpoint, key, and deployment name
mvn compile
mvn exec:java -Dexec.mainClass="FoundryClient"
```

#### JavaScript/Node.js
```bash
cd javascript
# Edit ..\..\.env with your Azure OpenAI endpoint, key, and deployment name
npm install
npm start
```

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
