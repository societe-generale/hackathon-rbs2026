import os
import requests
from dotenv import load_dotenv

load_dotenv()

class FoundryClient:
    def __init__(self):
        self.api_key = os.getenv('FOUNDRY_API_KEY')
        self.endpoint = os.getenv('FOUNDRY_ENDPOINT')

        if not self.api_key or not self.endpoint:
            raise ValueError('FOUNDRY_API_KEY and FOUNDRY_ENDPOINT must be set in .env file')

    def query(self, system_prompt: str, query: str) -> str:
        headers = {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json'
        }

        payload = {
            'system_prompt': system_prompt,
            'query': query
        }

        response = requests.post(f'{self.endpoint}/query', json=payload, headers=headers)
        response.raise_for_status()

        return response.json().get('answer', '')


if __name__ == '__main__':
    client = FoundryClient()

    system_prompt = "You are a helpful assistant."
    user_query = "What is 2 + 2?"

    answer = client.query(system_prompt, user_query)
    print(f"Query: {user_query}")
    print(f"Answer: {answer}")
