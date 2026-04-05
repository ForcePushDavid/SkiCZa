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
- Forces format strictly to `AVFormatIDKey: kAudioFormatLinearPCM`.
- Applies `.int16` depth and rejects floating-point layout ensuring compatibility with internal C++ downstream pipelines.

### WhisperService
Invokes the compiled binary `whisper-cli`:
- Leverages the default process lifecycle wrapper to pass path specifications directly (transcribing acoustically with no text bias).
- Suspends background computation via `process.waitUntilExit()` forcing aggressive RAM cleanup immediately once transcription concludes.
- Retrieves decoded string from stdout pipe.

### OllamaService
Provides textual shaping via `URLSession`:
- Communicates directly with locally-bound API (`http://localhost:11434/api/generate`).
- Requires `keep_alive: 0` explicitly encoded inside the payload JSON to unload the model instantly after processing, and `num_ctx: 2048` to strictly limit the initial VRAM allocation buffer.
- Utilizes an absolute base temperature scaling parameter (0.2) ensuring minimal structural hallucination.
