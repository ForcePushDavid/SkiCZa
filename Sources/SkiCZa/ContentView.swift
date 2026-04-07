import SwiftUI

struct HistoryItem: Codable, Identifiable {
    let id: UUID
    let date: Date
    let text: String
}

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var transcription: String = ""
    @State private var rawTranscription: String = ""
    @State private var isShowingRaw = false
    @State private var machineState: String = "Připraven"
    
    // Persistent Settings
    @AppStorage("vocabulary") private var vocabulary: String = ""
    @AppStorage("promptAddon") private var promptAddon: String = ""
    @AppStorage("chatTheme") private var chatTheme: String = ""
    @AppStorage("temperature") private var temperature: Double = 0.3
    @AppStorage("topP") private var topP: Double = 0.9
    @AppStorage("disableLLM") private var disableLLM: Bool = false
    
    // History Persistence
    @AppStorage("history_json") private var historyJSON: String = "[]"
    @State private var history: [HistoryItem] = []
    @State private var showInfo = false
    @State private var showSettings = false
    @AppStorage("showHistory") private var showHistory = true
    
    // Status State
    @State private var ollamaOnline: Bool? = nil
    @State private var ollamaModelPulled: Bool? = nil
    @State private var whisperCliExists: Bool? = nil
    @State private var whisperModelExists: Bool? = nil
    @State private var statusTimer: Timer?
    
    // Fix Action State
    @State private var isFixingOllamaModel = false
    @State private var isFixingWhisperModel = false
    @State private var whisperDownloadProgress: Double = 0
    
    var body: some View {
        HStack(spacing: 0) {
            // Main Editor Area (Left)
            VStack(spacing: 0) {
                // Top Bar
                HStack(spacing: 15) {
                    Spacer()
                    
                    Button(action: { showInfo.toggle() }) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showInfo) {
                        ScrollView {
                            VStack(spacing: 12) {
                                Text("SkiCZa v1.1.0")
                                    .font(.headline)
                                Text("Autor: David Jeřela")
                                    .font(.subheadline)
                                
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Použitý software:").font(.caption).bold()
                                    
                                    Group {
                                        Text("• Whisper (OpenAI/ggerganov)").font(.caption2).bold()
                                        Text("  Transcription engine (MIT License)").font(.system(size: 8))
                                        
                                        Text("• Ollama").font(.caption2).bold()
                                        Text("  Local LLM runner (MIT License)").font(.system(size: 8))
                                        
                                        Text("• Qwen2.5 Model (Alibaba Cloud)").font(.caption2).bold()
                                        Text("  Refinement logic (Apache 2.0 License)").font(.system(size: 8))
                                    }
                                    .foregroundColor(.secondary)
                                }
                                
                                Divider()
                                
                                Text("Licence MIT (SkiCZa)")
                                    .font(.caption).bold()
                                
                                Text("""
                                Copyright © 2026 David Jeřela

                                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                                THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                                """)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            }
                            .padding()
                        }
                        .frame(width: 320, height: 450)
                    }
                    
                    Button(action: { withAnimation { showSettings.toggle() } }) {
                        Image(systemName: showSettings ? "gearshape.fill" : "gearshape")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)

                    Button(action: { withAnimation { showHistory.toggle() } }) {
                        Image(systemName: "sidebar.right")
                            .font(.title3)
                            .foregroundColor(showHistory ? .blue : .primary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(.ultraThinMaterial)

                if showSettings {
                    SettingsPanel(
                        vocabulary: $vocabulary,
                        chatTheme: $chatTheme,
                        promptAddon: $promptAddon,
                        temperature: $temperature,
                        topP: $topP,
                        disableLLM: $disableLLM,
                        ollamaOnline: ollamaOnline,
                        ollamaModelPulled: ollamaModelPulled,
                        whisperCliExists: whisperCliExists,
                        whisperModelExists: whisperModelExists,
                        isFixingOllamaModel: $isFixingOllamaModel,
                        isFixingWhisperModel: $isFixingWhisperModel,
                        whisperDownloadProgress: whisperDownloadProgress,
                        onFixOllamaModel: { pullOllamaModel() },
                        onFixWhisperModel: { downloadWhisperModel() }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                ScrollView {
                    VStack(spacing: 20) {
                        Text(machineState)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top)

                        ZStack(alignment: .topTrailing) {
                            TextEditor(text: isShowingRaw ? $rawTranscription : $transcription)
                                .font(.system(.body, design: .rounded))
                                .frame(minHeight: 300)
                                .padding()
                                .scrollContentBackground(.hidden)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(12)
                            
                            if !rawTranscription.isEmpty && !disableLLM {
                                Button(action: { withAnimation { isShowingRaw.toggle() } }) {
                                    Image(systemName: isShowingRaw ? "sparkles" : "arrow.uturn.backward")
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(8)
                                        .shadow(radius: 2)
                                }
                                .padding(20)
                                .help(isShowingRaw ? "Zobrazit AI verzi" : "Zobrazit původní přepis")
                            }
                        }
                        .padding(.horizontal)

                        // Big Apple-style Record Button with Waveform
                        ZStack {
                            if audioRecorder.isRecording {
                                // Animated Waveform Rings
                                ForEach(0..<3) { i in
                                    Circle()
                                        .stroke(Color.red.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                                        .frame(width: 80 + CGFloat(audioRecorder.audioLevel * 100) + CGFloat(i * 20))
                                        .scaleEffect(audioRecorder.isRecording ? 1.0 : 0.8)
                                        .animation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true), value: audioRecorder.audioLevel)
                                }
                            }
                            
                            Button(action: toggleRecording) {
                                ZStack {
                                    Circle()
                                        .fill(audioRecorder.isRecording ? Color.red.opacity(0.1) : Color.primary.opacity(0.05))
                                        .frame(width: 80, height: 80)
                                    
                                    if audioRecorder.isRecording {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.red)
                                            .frame(width: 30, height: 30)
                                            .transition(.scale)
                                    } else {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 65, height: 65)
                                            .overlay(
                                                Circle().stroke(Color.white, lineWidth: 3)
                                            )
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(height: 180) // Space for waveform
                        .padding(.bottom, 10)
                        
                        Button(action: copyToPasteboard) {
                            Label("Kopírovat výsledek", systemImage: "doc.on.doc")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                        .padding(.bottom, 30)
                    }
                }
            }
            .frame(minWidth: 400)
            
            if showHistory {
                Divider()
                historySidebar
                    .transition(.move(edge: .trailing))
            }
        }
        .onAppear {
            loadHistory()
            startStatusChecks()
        }
        .onDisappear {
            statusTimer?.invalidate()
        }
    }
    
    private func startStatusChecks() {
        checkStatus()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                self.checkStatus()
            }
        }
    }
    
    private func checkStatus() {
        // Check local files
        let checks = SystemCheckService.shared.checkPrerequisites()
        self.whisperCliExists = checks.whisperCli
        self.whisperModelExists = checks.whisperModel
        
        // Check Ollama
        OllamaService.shared.checkStatus { online, pulled in
            Task { @MainActor in
                self.ollamaOnline = online
                self.ollamaModelPulled = pulled
            }
        }
    }
    
    private func pullOllamaModel() {
        isFixingOllamaModel = true
        OllamaService.shared.pullModel { success in
            Task { @MainActor in
                self.isFixingOllamaModel = false
                self.checkStatus()
            }
        }
    }
    
    private func downloadWhisperModel() {
        isFixingWhisperModel = true
        SystemCheckService.shared.downloadWhisperModel(progress: { prog in
            Task { @MainActor in self.whisperDownloadProgress = prog }
        }) { success in
            Task { @MainActor in
                self.isFixingWhisperModel = false
                self.whisperDownloadProgress = 0
                self.checkStatus()
            }
        }
    }

    private var historySidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Historie")
                    .font(.headline)
                Spacer()
                Button(action: { history = []; saveHistory() }) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            
            List(selection: $transcription) {
                ForEach(history) { item in
                    VStack(alignment: .leading) {
                        Text(item.text)
                            .lineLimit(2)
                            .font(.subheadline)
                        Text(item.date, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .tag(item.text)
                }
                .onDelete(perform: deleteHistory)
            }
            .listStyle(.sidebar)
        }
        .frame(width: 250)
    }

    private func toggleRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
            processRecording()
        } else {
            self.transcription = ""
            self.rawTranscription = ""
            self.isShowingRaw = false
            audioRecorder.startRecording()
            machineState = "Nahrávám..."
        }
    }

    private func processRecording() {
        machineState = "Přepisuji..."
        guard let url = audioRecorder.recordingURL else { return }
        
        WhisperService.shared.transcribe(audioFileURL: url, vocabulary: vocabulary) { transcribedText in
            Task { @MainActor in
                guard let rawText = transcribedText else {
                    machineState = "Chyba přepisu"
                    return
                }
                
                withAnimation {
                    self.rawTranscription = rawText
                    self.transcription = rawText
                    self.isShowingRaw = false
                }
                
                if disableLLM {
                    machineState = "Hotovo (Bez AI)"
                    addToHistory(text: rawText)
                    return
                }
                
                machineState = "Leštím... (Ollama)"
                
                OllamaService.shared.formatText(
                    whisperText: rawText,
                    promptAddon: promptAddon,
                    theme: chatTheme,
                    temperature: temperature,
                    topP: topP
                ) { finalOutput in
                    Task { @MainActor in
                        if let final = finalOutput, !final.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            withAnimation(.easeInOut) {
                                self.transcription = final
                                machineState = "Hotovo"
                                addToHistory(text: final)
                            }
                        } else {
                            machineState = "Prázdný záznam"
                            self.transcription = rawText
                        }
                    }
                }
            }
        }
    }

    private func addToHistory(text: String) {
        let newItem = HistoryItem(id: UUID(), date: Date(), text: text)
        history.insert(newItem, at: 0)
        saveHistory()
    }

    private func deleteHistory(offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }

    private func loadHistory() {
        if let data = historyJSON.data(using: .utf8) {
            history = (try? JSONDecoder().decode([HistoryItem].self, from: data)) ?? []
        }
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            historyJSON = String(data: data, encoding: .utf8) ?? "[]"
        }
    }

    private func copyToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(transcription, forType: .string)
    }
}

struct SettingsPanel: View {
    @Binding var vocabulary: String
    @Binding var chatTheme: String
    @Binding var promptAddon: String
    @Binding var temperature: Double
    @Binding var topP: Double
    @Binding var disableLLM: Bool
    
    let ollamaOnline: Bool?
    let ollamaModelPulled: Bool?
    let whisperCliExists: Bool?
    let whisperModelExists: Bool?
    
    @Binding var isFixingOllamaModel: Bool
    @Binding var isFixingWhisperModel: Bool
    let whisperDownloadProgress: Double
    
    var onFixOllamaModel: () -> Void
    var onFixWhisperModel: () -> Void
    
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $selectedTab) {
                Text("Model").tag(0)
                Text("Systém").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 5)
            
            if selectedTab == 0 {
                modelTab
            } else {
                systemTab
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
    }
    
    private var modelTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                Text("Slovníček (Whisper Vocabulary)").font(.caption2).bold()
                TextField("Slova oddělená čárkou", text: $vocabulary).textFieldStyle(.roundedBorder)
            }
            
            Divider()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Téma").font(.caption2).bold()
                        TextField("Kontext", text: $chatTheme).textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading) {
                        Text("Addon").font(.caption2).bold()
                        TextField("Extra prompt", text: $promptAddon).textFieldStyle(.roundedBorder)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Temp: \(String(format: "%.1f", temperature))").font(.caption2)
                            Image(systemName: "info.circle").font(.caption2).foregroundColor(.secondary)
                                .help("Kreativita: 0.0 (striktní) až 1.0 (uvolněné)")
                        }
                        Slider(value: $temperature, in: 0...1.0, step: 0.1)
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Top_P: \(String(format: "%.1f", topP))").font(.caption2)
                            Image(systemName: "info.circle").font(.caption2).foregroundColor(.secondary)
                                .help("Rozsah slov: 0.1 (nejčastější) až 1.0 (všechna)")
                        }
                        Slider(value: $topP, in: 0...1.0, step: 0.1)
                    }
                }
            }
            .disabled(disableLLM)
            .opacity(disableLLM ? 0.5 : 1.0)

            Divider()

            Toggle("Vypnout LLM/AI úpravy", isOn: $disableLLM)
                .font(.subheadline).bold()
        }
    }
    
    private var systemTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Prerekvizity").font(.headline)
            
            statusRow(
                label: "Ollama Server",
                status: ollamaOnline,
                description: "localhost:11434",
                actionLabel: "Stáhnout",
                action: { NSWorkspace.shared.open(URL(string: "https://ollama.com/download")!) }
            )
            
            statusRow(
                label: "Model Qwen2.5:7b",
                status: ollamaModelPulled,
                description: "Lokální LLM",
                actionLabel: isFixingOllamaModel ? "Stahuji..." : "Stáhnout",
                isActionDisabled: !(ollamaOnline == true) || isFixingOllamaModel,
                action: onFixOllamaModel
            )
            
            statusRow(
                label: "Whisper CLI",
                status: whisperCliExists,
                description: "./whisper-cli",
                actionLabel: "Info",
                action: { NSWorkspace.shared.open(URL(string: "https://github.com/ggerganov/whisper.cpp")!) }
            )
            
            statusRow(
                label: "Whisper Model",
                status: whisperModelExists,
                description: "large-v3-turbo",
                actionLabel: isFixingWhisperModel ? "Stahuji..." : "Stáhnout",
                isActionDisabled: isFixingWhisperModel,
                action: onFixWhisperModel
            )
            
            if isFixingWhisperModel && whisperDownloadProgress > 0 {
                ProgressView(value: whisperDownloadProgress)
                    .progressViewStyle(.linear)
                    .padding(.top, 5)
            }
            
            if ollamaOnline == false {
                Text("⚠️ Ollama není spuštěna. Prosím spusťte aplikaci Ollama.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func statusRow(
        label: String,
        status: Bool?,
        description: String,
        actionLabel: String? = nil,
        isActionDisabled: Bool = false,
        action: (() -> Void)? = nil
    ) -> some View {
        HStack {
            Image(systemName: status == true ? "checkmark.circle.fill" : (status == false ? "xmark.circle.fill" : "circle"))
                .foregroundColor(status == true ? .green : (status == false ? .red : .secondary))
            
            VStack(alignment: .leading) {
                Text(label).font(.subheadline).bold()
                Text(description).font(.caption2).foregroundColor(.secondary)
            }
            
            Spacer()
            
            if status == false, let actionLabel = actionLabel, let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(isActionDisabled ? 0.3 : 1.0))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .disabled(isActionDisabled)
            } else {
                Text(status == true ? "Běží" : (status == false ? "Chybí" : "Hledám..."))
                    .font(.caption)
                    .foregroundColor(status == true ? .green : (status == false ? .red : .secondary))
            }
        }
        .padding(.vertical, 2)
    }
}
