import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate, @unchecked Sendable {
    var audioRecorder: AVAudioRecorder?
    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0
    var recordingURL: URL?
    private var timer: Timer?

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
                self.audioRecorder?.isMeteringEnabled = true
                self.audioRecorder?.record()
                self.isRecording = true
                
                DispatchQueue.main.async {
                    self.startMetering()
                }
                print("Started recording at \(self.recordingURL?.path ?? "")")
            } catch {
                print("Failed to start recording: \(error)")
            }
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopMetering()
        print("Stopped recording.")
    }

    private func startMetering() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.audioRecorder?.updateMeters()
            // Convert dB to 0...1 range
            let power = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
            let level = max(0, (CGFloat(power) + 50) / 50)  // Simple mapping
            self.audioLevel = Float(level)
        }
    }

    private func stopMetering() {
        timer?.invalidate()
        timer = nil
        audioLevel = 0.0
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully at \(recordingURL?.path ?? "")")
        } else {
            print("Recording failed")
        }
    }
}
