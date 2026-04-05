import SwiftUI

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var transcription: String = ""
    @State private var machineState: String = "Připraven"

    var body: some View {
        VStack(spacing: 20) {
            Text("Voice Editor")
                .font(.largeTitle)
                .padding(.top)

            Text("Stav: \(machineState)")
                .font(.headline)
                .foregroundColor(.blue)

            TextEditor(text: $transcription)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                )
                .frame(minHeight: 200)

            HStack {
                Button(action: {
                    audioRecorder.startRecording()
                    machineState = "Nahrávám..."
                }) {
                    Label("Nahrát (Record)", systemImage: "mic.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(audioRecorder.isRecording)

                Button(action: {
                    audioRecorder.stopRecording()
                    machineState = "Přepisuji..."
                    if let url = audioRecorder.recordingURL {
                        WhisperService.shared.transcribe(audioFileURL: url) { transcribedText in
                            Task { @MainActor in
                                guard let transcribedText = transcribedText else {
                                    self.machineState = "Chyba přepisu"
                                    return
                                }
                                
                                self.machineState = "Upravuji..."
                                OllamaService.shared.formatText(whisperText: transcribedText) { finalOutput in
                                    Task { @MainActor in
                                        if let finalOutput = finalOutput {
                                            self.transcription = finalOutput
                                            self.machineState = "Hotovo"
                                        } else {
                                            self.machineState = "Chyba úprav (Ollama)"
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        machineState = "Chyba: Zvuk není k dispozici."
                    }
                }) {
                    Label("Zastavit", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!audioRecorder.isRecording)

                Spacer()

                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(transcription, forType: .string)
                }) {
                    Label("Kopírovat", systemImage: "doc.on.doc")
                }
            }
            .padding(.bottom)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}
