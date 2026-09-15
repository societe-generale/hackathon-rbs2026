import dotenv from 'dotenv';

dotenv.config();

class FoundryClient {
  constructor() {
    this.apiKey = process.env.FOUNDRY_API_KEY;
    this.endpoint = process.env.FOUNDRY_ENDPOINT;

    if (!this.apiKey || !this.endpoint) {
      throw new Error('FOUNDRY_API_KEY and FOUNDRY_ENDPOINT must be set in .env file');
    }
  }

  async query(systemPrompt, query) {
    const payload = {
      system_prompt: systemPrompt,
      query: query
    };

    const response = await fetch(`${this.endpoint}/query`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      throw new Error(`API Error: ${response.statusText}`);
    }

    const data = await response.json();
    return data.answer;
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
