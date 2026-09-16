import json


TOOLS = [
    {
        'type': 'function',
        'name': 'add_numbers',
        'description': 'Add two numbers together.',
        'parameters': {
            'type': 'object',
            'properties': {
                'first': {'type': 'number'},
                'second': {'type': 'number'},
            },
            'required': ['first', 'second'],
            'additionalProperties': False,
        },
        'strict': True,
    }
]


def add_numbers(first: float, second: float) -> float:
    return first + second


def execute_tool(name: str, arguments: str) -> str:
    if name == 'add_numbers':
        result = add_numbers(**json.loads(arguments))
        return str(result)

    raise ValueError(f'Unknown tool: {name}')