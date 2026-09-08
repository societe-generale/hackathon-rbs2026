import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import io.github.cdimascio.dotenv.Dotenv;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class FoundryClient {
    private String apiKey;
    private String endpoint;

    public FoundryClient() {
        Dotenv dotenv = Dotenv.load();
        this.apiKey = dotenv.get("FOUNDRY_API_KEY");
        this.endpoint = dotenv.get("FOUNDRY_ENDPOINT");

        if (apiKey == null || endpoint == null) {
            throw new IllegalArgumentException("FOUNDRY_API_KEY and FOUNDRY_ENDPOINT must be set in .env file");
        }
    }

    public String query(String systemPrompt, String query) throws Exception {
        HttpClient client = HttpClient.newHttpClient();

        JsonObject payload = new JsonObject();
        payload.addProperty("system_prompt", systemPrompt);
        payload.addProperty("query", query);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(new URI(endpoint + "/query"))
                .header("Authorization", "Bearer " + apiKey)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(payload.toString()))
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
        response.body();

        JsonObject jsonResponse = JsonParser.parseString(response.body()).getAsJsonObject();
        return jsonResponse.get("answer").getAsString();
    }

    public static void main(String[] args) throws Exception {
        FoundryClient client = new FoundryClient();

        String systemPrompt = "You are a helpful assistant.";
        String userQuery = "What is 2 + 2?";

        String answer = client.query(systemPrompt, userQuery);
        System.out.println("Query: " + userQuery);
        System.out.println("Answer: " + answer);
    }
}
