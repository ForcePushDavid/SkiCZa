# Technical Documentation

## Component Overview

### SkiCZaApp
The main application lifecycle handler, instantiated with the `@main` property. Exposes the primary scene routing to the `ContentView`.

### ContentView
Contains the reactive states controlling the UI flow:
- `IsRecording`: Toggles the record buttons.
- `MachineState`: Progress indicator exposing steps: Pripraven, Nahravam, Prepisuji, Upravuji, Hotovo.
- `Transcription`: Holds the final string value for display and copying.

### AudioService
Wraps `AVAudioRecorder` logic:
- Acquires `.audio` capture device privileges natively.
- Forces format strictly to `AVFormatIDKey: kAudioFormatLinearPCM` at 16kHz.
- **New:** Implements real-time audio metering (`audioLevel`) polled via Timer to drive the UI waveform.

### WhisperService
Invokes the compiled binary `whisper-cli`:
- Leverages the default process lifecycle wrapper.
- **New:** Implements an aggressive hallucination filter for common repetitive outputs (e.g., "Konec.", "Titulky.") and silence-induced artifacts.
- Suspends background computation via `process.waitUntilExit()` for RAM cleanup.

### OllamaService
Provides textual shaping via `URLSession`:
- Communicates with `http://localhost:11434/api/generate`.
- **New:** Includes a guard against empty or excessively short transcriptions to prevent meaningless LLM responses.
- Uses a refined system prompt for deterministic grammatical correction and filler word removal.

## Future Roadmap

### 1. Daily Usage Enhancements (UX)
- **Global Keyboard Shortcut:** Listen in the background for a global hotkey to trigger recording immediately from any application.
- **Menu Bar Integration:** Run as a persistent, hidden background app accessible purely from the macOS top menu bar, removing dock presence.
- **Auto-Paste Hook:** Automatically paste the finalized LLM output into the active OS window using `CGEvent` clipboard simulation.

### 2. Engine and Hardware Optimization
- TBD

### 3. Feature Extensions
- **Contextual UI Profiles:** Offer UI toggles (e.g., Medical, IT) to dynamically modify Whisper's acoustic vocabulary prompt, further boosting domain-specific reliability before LLM correction.
