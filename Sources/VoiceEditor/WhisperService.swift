import Foundation

final class WhisperService: @unchecked Sendable {
    static let shared = WhisperService()
    
    func transcribe(audioFileURL: URL, completion: @escaping @Sendable (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            let pipe = Pipe()
            
            // Expected that the binary `whisper-cli` from whisper.cpp is in current working directory
            process.executableURL = URL(fileURLWithPath: "./whisper-cli")
            process.arguments = [
                "--model", "models/ggml-large-v3-turbo.bin",
                "-f", audioFileURL.path,
                "-l", "cs", // Force Czech language
                "-nt" // Use -nt (no timestamps) so we just get the clean text without [00:00:00] tags
            ]
            
            process.standardOutput = pipe
            process.standardError = Pipe() // Ignore stderr to avoid spam
            
            do {
                try process.run()
                process.waitUntilExit() // Wait for it to finish and free RAM entirely
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let cleanedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
                    DispatchQueue.main.async {
                        completion(cleanedOutput.isEmpty ? nil : cleanedOutput)
                    }
                } else {
                    DispatchQueue.main.async { completion(nil) }
                }
            } catch {
                print("Failed to run whisper.cpp: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
}
