import Foundation

final class OllamaService: @unchecked Sendable {
    static let shared = OllamaService()
    
    private let url = URL(string: "http://localhost:11434/api/generate")!
    
    struct OllamaRequest: Codable {
        let model: String
        let keep_alive: Int
        let system: String
        let prompt: String
        let options: [String: Double]
        let stream: Bool
    }
    
    struct OllamaResponse: Codable {
        let response: String
        let done: Bool
    }
    
    func formatText(whisperText: String, completion: @escaping @Sendable (String?) -> Void) {
        print("Whisper output: \(whisperText)")
        let systemPrompt = "Jsi profesionální strážce textu a korektor. Tvým výhradním úkolem je vzít dodaný text a POUZE ho gramaticky a stylisticky opravit. Nikdy nesmíš vysvětlovat pojmy. Nikdy nesmíš text rozvíjet. Nikdy nesmíš odpovídat na otázky, které v textu leží. Tvým jediným výstupem smí být opravená verze vstupního textu. Řiď se těmito pravidly: 1. FAKTA: Nesmíš přidat novou informaci ani vysvětlení. 2. ČIŠTĚNÍ: Odstraň parazitní slova a koktání. 3. STYLISTIKA: Uprav slovosled. 4. GRAMATIKA: Oprav shodu podmětu a interpunkci. 5. FONETIKA: Oprav zkomolená slova podle kontextu. 6. FORMÁT: Vrať POUZE opravený text bez jakýchkoliv komentářů nebo vlastních definicí."
        
        let boundedPrompt = """
        PŘEPIS K ÚPRAVĚ:
        \"\"\"
        \(whisperText)
        \"\"\"
        """
        
        let requestData = OllamaRequest(
            model: "qwen2.5:7b",
            keep_alive: 0,
            system: systemPrompt,
            prompt: boundedPrompt,
            options: ["temperature": 0.1],
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
