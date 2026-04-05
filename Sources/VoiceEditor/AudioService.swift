import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate, @unchecked Sendable {
    var audioRecorder: AVAudioRecorder?
    @Published var isRecording = false
    var recordingURL: URL?

    func requestPermission(completion: @escaping @Sendable (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func startRecording() {
        requestPermission { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                print("Microphone access denied")
                return
            }
            
            let tempDir = FileManager.default.temporaryDirectory
            self.recordingURL = tempDir.appendingPathComponent("voice_editor_temp.wav")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 16000.0,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            do {
                self.audioRecorder = try AVAudioRecorder(url: self.recordingURL!, settings: settings)
                self.audioRecorder?.delegate = self
                self.audioRecorder?.record()
                self.isRecording = true
                print("Started recording at \(self.recordingURL?.path ?? "")")
            } catch {
                print("Failed to start recording: \(error)")
            }
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        print("Stopped recording.")
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully at \(recordingURL?.path ?? "")")
            // Here we will later trigger Whisper via a callback or notification
        } else {
            print("Recording failed")
        }
    }
}
