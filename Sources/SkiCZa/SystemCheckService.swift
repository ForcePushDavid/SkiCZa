import Foundation

final class SystemCheckService: NSObject, @unchecked Sendable, URLSessionDownloadDelegate {
    static let shared = SystemCheckService()
    
    private var progressHandler: (@Sendable (Double) -> Void)?
    private var completionHandler: (@Sendable (Bool) -> Void)?
    private let modelURL = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin")!
    private let destination = URL(fileURLWithPath: "./models/ggml-large-v3-turbo.bin")

    func checkFileExists(at path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    func checkPrerequisites() -> (whisperCli: Bool, whisperModel: Bool) {
        let cli = checkFileExists(at: "./whisper-cli")
        let model = checkFileExists(at: "./models/ggml-large-v3-turbo.bin")
        return (cli, model)
    }
    
    func downloadWhisperModel(progress: @escaping @Sendable (Double) -> Void, completion: @escaping @Sendable (Bool) -> Void) {
        self.progressHandler = progress
        self.completionHandler = completion
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: modelURL)
        task.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
            completionHandler?(true)
        } catch {
            completionHandler?(false)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressHandler?(progress)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download error: \(error)")
            completionHandler?(false)
        }
    }
}
