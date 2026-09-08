# Foundry Starter Module

Simple starter modules for connecting to Foundry endpoint in Python, Java, and JavaScript.

## Getting Started

Each language folder has the same structure:
- `.env.example` - Configuration template
- Language-specific dependencies/build files
- `client.py` / `FoundryClient.java` / `client.js` - Simple client to query Foundry

### Setup Steps for Each Language

#### Python
```bash
cd python
cp .env.example .env
# Edit .env with your FOUNDRY_API_KEY and FOUNDRY_ENDPOINT
uv sync
uv run client.py
```

#### Java
```bash
cd java
cp .env.example .env
# Edit .env with your FOUNDRY_API_KEY and FOUNDRY_ENDPOINT
mvn compile
mvn exec:java -Dexec.mainClass="FoundryClient"
```

#### JavaScript/Node.js
```bash
cd javascript
cp .env.example .env
# Edit .env with your FOUNDRY_API_KEY and FOUNDRY_ENDPOINT
npm install
npm start
```

## Configuration

All modules use a `.env` file for configuration:

```
FOUNDRY_API_KEY=your_api_key_here
FOUNDRY_ENDPOINT=https://your-foundry-endpoint.com/api
```

Replace with your actual Foundry API key and endpoint URL.

## What It Does

Each client:
1. Loads configuration from `.env`
2. Takes a system prompt and user query
3. Sends them to the Foundry endpoint via POST request
4. Returns the answer

## Customization

You can easily extend each client to:
- Add more methods (e.g., for different types of requests)
- Handle different response formats
- Add error handling specific to your needs
- Integrate with your application
