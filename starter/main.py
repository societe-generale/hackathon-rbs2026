from client import FoundryClient


def main() -> None:
    client = FoundryClient()

    system_prompt = (
        "You are a helpful assistant. Use the add_numbers tool when arithmetic "
        "is needed. You should always answer in French in full sentences."
    )
    user_query = "What is 45668 + 534596 ?"

    print(f"Query: {user_query}")
    answer = client.query(system_prompt, user_query)
    print(f"Answer: {answer}")


if __name__ == '__main__':
    main()