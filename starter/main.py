from client import FoundryClient


def main() -> None:
    client = FoundryClient()

    system_prompt = (
        "You are a helpful assistant. Use the calculate tool when arithmetic "
        "is needed. You should always answer in French in full sentences."
    )
    user_query = (
        "J'ai acheté 12 caisses de fruits pour un montant total de 180 €. "
        "Combien j'ai gagné au total ?"
    )

    print(f"Query: {user_query}")
    answer = client.query(system_prompt, user_query)
    print(f"Answer: {answer}")


if __name__ == '__main__':
    main()