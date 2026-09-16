from openai import OpenAI

endpoint = "https://foundry-hackathon-rbs2026-adam.services.ai.azure.com/openai/v1"
deployment_name = "gpt-5.6-terra"
api_key = "Qczxz6cxRVQwYpcE6qDbARMKMcnrRn4IUW9q6etOblczjEu2zQyMJQQJ99CIACfhMk5XJ3w3AAAAACOGP1ru"

client = OpenAI(
    base_url=endpoint,
    api_key=api_key
)

response = client.responses.create(
    model=deployment_name,
    input="What is the capital of France?",
)

print(f"answer: {response.output[0]}")
