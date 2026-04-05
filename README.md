# SkiCZa

SkiCZa is a native macOS application built with SwiftUI for offline audio recording, local transcription via Whisper.cpp, and automated text correction with Ollama. The application is strictly optimized for Apple Silicon and processes everything locally with no cloud dependencies.

## Architecture and Stack
- SwiftUI & Swift: Native user interface and application lifecycle management.
- AVFoundation: Microphone capture configured explicitly for 16-bit PCM integer output at 16kHz to ensure precise transcription.
- Whisper.cpp: Local speech-to-text inference instantiated via NSTask/Process, running the ggml-small model.
- Ollama API (qwen2.5:7b): Local REST API endpoint formatting the text to remove filler words and fix grammar while keeping VRAM utilization strict.

## Prerequisites
- macOS 13 or later running on Apple Silicon.
- Installed Ollama instance running locally on port 11434 with the qwen2.5:7b model pulled.
- Whisper.cpp executable (whisper-cli) and ggml-small.bin weight model situated alongside the executable.

## Execution
Run the app dynamically inside the CLI:
`swift run`

Select "Nahrat", speak into the microphone, then select "Zastavit". The processing transitions sequentially from transcription directly into text shaping. Finished output can be placed into the system clipboard via NSPasteboard.

## License
MIT
