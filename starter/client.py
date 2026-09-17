import os
import json
from pathlib import Path
from dotenv import load_dotenv
from openai import OpenAI
from tools import TOOLS, execute_tool

load_dotenv(Path(__file__).resolve().parent / '.env')


class FoundryClient:
    def __init__(self):
        self.api_key = os.getenv('AZURE_OPENAI_API_KEY')
        configured_endpoint = os.getenv('AZURE_OPENAI_ENDPOINT', '').rstrip('/')
        if '/api/projects/' in configured_endpoint:
            configured_endpoint = configured_endpoint.split('/api/projects/', 1)[0]
        self.endpoint = (
            configured_endpoint
            if configured_endpoint.endswith('/openai/v1')
            else f'{configured_endpoint}/openai/v1'
        )
        self.deployment_name = os.getenv('AZURE_OPENAI_DEPLOYMENT_NAME')

        if not self.api_key or not self.endpoint or not self.deployment_name:
            raise ValueError(
                'AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, and '
                'AZURE_OPENAI_DEPLOYMENT_NAME must be set in .env file'
            )

        self.client = OpenAI(
            base_url=self.endpoint,
            api_key=self.api_key,
        )

    def query(self, system_prompt: str, query: str) -> str:
        response = self.client.responses.create(
            model=self.deployment_name,
            instructions=system_prompt,
            input=query,
            tools=TOOLS,
        )

        while True:
            tool_outputs = []
            for item in response.output:
                if item.type != 'function_call':
                    continue

                print(
                    'Tool call metadata:',
                    json.dumps(
                        {
                            'type': item.type,
                            'name': item.name,
                            'call_id': item.call_id,
                            'arguments': json.loads(item.arguments),
                        },
                        indent=2,
                    ),
                )
                tool_outputs.append({
                    'type': 'function_call_output',
                    'call_id': item.call_id,
                    'output': execute_tool(item.name, item.arguments),
                })

            if not tool_outputs:
                break

            response = self.client.responses.create(
                model=self.deployment_name,
                instructions=system_prompt,
                previous_response_id=response.id,
                input=tool_outputs,
                tools=TOOLS,
            )

        return response.output_text
