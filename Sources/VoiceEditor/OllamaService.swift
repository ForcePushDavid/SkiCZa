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
        let systemPrompt = "Jsi profesionální český editor a korektor. Tvým výhradním úkolem je transformovat hrubý, mluvený a často kostrbatý přepis zvuku do plynulého, srozumitelného a gramaticky bezchybného psaného textu. Při úpravě textu se striktně řiď těmito pravidly: 1. FAKTA: Nesmíš přidat žádnou novou informaci. Nesmíš odstranit žádný fakt. 2. ČIŠTĚNÍ: Odstraň parazitní slova a koktání. 3. STYLISTIKA: Uprav slovosled, spojuj věty do logických souvětí. 4. GRAMATIKA: Oprav shodu podmětu s přísudkem a interpunkci. 5. FORMÁT VÝSTUPU: Vrať POUZE upravený text bez jakýchkoliv komentářů."
        
        let requestData = OllamaRequest(
            model: "qwen2.5:7b",
            keep_alive: 0,
            system: systemPrompt,
            prompt: whisperText,
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
