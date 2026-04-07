import Foundation

final class OllamaService: @unchecked Sendable {
    static let shared = OllamaService()
    
    private let url = URL(string: "http://localhost:11434/api/generate")!
    
    struct OllamaOptions: Codable {
        let temperature: Double
        let num_ctx: Int
        let top_p: Double
    }
    
    struct OllamaRequest: Codable {
        let model: String
        let keep_alive: Int
        let system: String
        let prompt: String
        let options: OllamaOptions
        let stream: Bool
    }
    
    struct OllamaResponse: Codable {
        let response: String
        let done: Bool
    }
    
    func formatText(
        whisperText: String,
        promptAddon: String,
        theme: String,
        temperature: Double,
        topP: Double,
        completion: @escaping @Sendable (String?) -> Void
    ) {
        let trimmed = whisperText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.count < 3 {
             print("OllamaService: Skipping empty or too short input")
             DispatchQueue.main.async { completion(nil) }
             return
        }

        print("Whisper output: \(whisperText)")
        var systemPrompt = "Jsi profesionální editor českého přepisu. OPRAV Gramatiku, Smaž výplňková slova. VRACEJ POUZE FINÁLNÍ TEXT. Pokud je vstup nesmyslný nebo obsahuje jen halucinace, vrať prázdný řetězec. NEKOMENTUJ SVOU ČINNOST."
        
        if !promptAddon.isEmpty {
            systemPrompt += "\n\nDALŠÍ INSTRUKCE UŽIVATELE (Při rozporu mají přednost): \(promptAddon)"
        }
        
        if !theme.isEmpty {
            systemPrompt += "\n\nTÉMA/KONTEXT TEXTU: \(theme)"
        }
        
        let boundedPrompt = "PŘEPIS K ÚPRAVĚ:\n\(whisperText)"
        
        let requestData = OllamaRequest(
            model: "qwen2.5:7b",
            keep_alive: 0,
            system: systemPrompt,
            prompt: boundedPrompt,
            options: OllamaOptions(temperature: temperature, num_ctx: 1024, top_p: topP),
            stream: false
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestData)
        } catch {
            print("Failed to encode Ollama request: \(error)")
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ollama API error: \(error)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
                print("Ollama output: \(ollamaResponse.response)")
                DispatchQueue.main.async {
                    completion(ollamaResponse.response)
                }
            } catch {
                print("Failed to decode Ollama response: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
        task.resume()
    }
}
