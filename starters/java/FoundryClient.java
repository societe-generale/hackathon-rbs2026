import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import io.github.cdimascio.dotenv.Dotenv;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Path;

public class FoundryClient {
    private String apiKey;
    private String endpoint;
    private String deploymentName;

    public FoundryClient() {
        Path envFile = Path.of("..", "..", ".env").toAbsolutePath().normalize();
        Dotenv dotenv = Dotenv.configure()
            .directory(envFile.getParent().toString())
            .filename(envFile.getFileName().toString())
            .load();
        this.apiKey = dotenv.get("AZURE_OPENAI_API_KEY");
        String configuredEndpoint = dotenv.get("AZURE_OPENAI_ENDPOINT");
        this.deploymentName = dotenv.get("AZURE_OPENAI_DEPLOYMENT_NAME");

        if (configuredEndpoint != null) {
            configuredEndpoint = configuredEndpoint.replaceAll("/+$", "");
            if (configuredEndpoint.contains("/api/projects/")) {
                configuredEndpoint = configuredEndpoint.split("/api/projects/", 2)[0];
            }
            this.endpoint = configuredEndpoint.endsWith("/openai/v1")
                    ? configuredEndpoint
                    : configuredEndpoint + "/openai/v1";
        }

        if (apiKey == null || endpoint == null || deploymentName == null) {
            throw new IllegalArgumentException("AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, and AZURE_OPENAI_DEPLOYMENT_NAME must be set in .env file");
        }
    }

    public String query(String systemPrompt, String query) throws Exception {
        HttpClient client = HttpClient.newHttpClient();

        JsonObject payload = new JsonObject();
        payload.addProperty("model", deploymentName);
        payload.addProperty("instructions", systemPrompt);
        payload.addProperty("input", query);

        HttpRequest request = HttpRequest.newBuilder()
            .uri(new URI(endpoint + "/responses"))
                .header("Authorization", "Bearer " + apiKey)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(payload.toString()))
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IllegalStateException("API Error " + response.statusCode() + ": " + response.body());
        }

        JsonObject jsonResponse = JsonParser.parseString(response.body()).getAsJsonObject();
        StringBuilder answer = new StringBuilder();
        jsonResponse.getAsJsonArray("output").forEach(output -> {
            output.getAsJsonObject().getAsJsonArray("content").forEach(content -> {
                JsonObject contentObject = content.getAsJsonObject();
                if ("output_text".equals(contentObject.get("type").getAsString())) {
                    answer.append(contentObject.get("text").getAsString());
                }
            });
        });
        return answer.toString();
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
