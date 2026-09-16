import dotenv from 'dotenv';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const workspaceRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
dotenv.config({ path: path.join(workspaceRoot, '.env') });

class FoundryClient {
  constructor() {
    this.apiKey = process.env.AZURE_OPENAI_API_KEY;
    const configuredEndpoint = (process.env.AZURE_OPENAI_ENDPOINT || '').replace(/\/$/, '');
    this.endpoint = configuredEndpoint.includes('/api/projects/')
      ? configuredEndpoint.split('/api/projects/')[0] + '/openai/v1'
      : configuredEndpoint.endsWith('/openai/v1')
        ? configuredEndpoint
        : `${configuredEndpoint}/openai/v1`;
    this.deploymentName = process.env.AZURE_OPENAI_DEPLOYMENT_NAME;

    if (!this.apiKey || !configuredEndpoint || !this.deploymentName) {
      throw new Error('AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, and AZURE_OPENAI_DEPLOYMENT_NAME must be set in .env file');
    }
  }

  async query(systemPrompt, query) {
    const payload = {
      model: this.deploymentName,
      instructions: systemPrompt,
      input: query
    };

    const response = await fetch(`${this.endpoint}/responses`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      throw new Error(`API Error ${response.status}: ${await response.text()}`);
    }

    const data = await response.json();
    return data.output
      .flatMap(item => item.content || [])
      .filter(content => content.type === 'output_text')
      .map(content => content.text)
      .join('');
  }
}

async function main() {
  const client = new FoundryClient();

  const systemPrompt = 'You are a helpful assistant.';
  const userQuery = 'What is 2 + 2?';

  try {
    const answer = await client.query(systemPrompt, userQuery);
    console.log(`Query: ${userQuery}`);
    console.log(`Answer: ${answer}`);
  } catch (error) {
    console.error('Error:', error.message);
  }
}

main();
