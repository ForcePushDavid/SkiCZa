# SkiCZa

SkiCZa is a native macOS application built with SwiftUI for offline audio recording, local transcription via Whisper.cpp, and automated text correction with Ollama. The application is strictly optimized for Apple Silicon and processes everything locally with no cloud dependencies. Created primary for Czech Language. Language switch may come later.

## Architecture and Stack
- SwiftUI & Swift: Native user interface and application lifecycle management.
- AVFoundation: Microphone capture configured explicitly for 16-bit PCM integer output at 16kHz to ensure precise transcription.
- Whisper.cpp: Local speech-to-text inference instantiated via NSTask/Process, running the `ggml-large-v3-turbo` model with custom hallucination filters.
- Ollama API (qwen2.5:7b): Local REST API endpoint formatting the text with custom system prompts, context steering, and guard rails for empty input.
- Real-time Waveform: Animated visual feedback during recording based on real-time audio metering.

## Prerequisites
- macOS 13 or later running on Apple Silicon.
- Installed Ollama instance running locally on port 11434 with the `qwen2.5:7b` model pulled.
- `whisper-cli` binary and `ggml-large-v3-turbo.bin` model located in the current working directory.

## Execution & Build
- **Dev mode:** `swift run`
- **Standalone .app:** See `walkthrough.md` for instructions on building a full macOS application bundle with the provided `Resources/AppIcon.png`.

## Acknowledgments & Third-party Software
This project utilizes the following open-source components:
- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) by Georgi Gerganov and OpenAI (MIT License).
- [Ollama](https://ollama.com/) (MIT License).
- [Qwen2.5 Model](https://github.com/QwenLM/Qwen) by Alibaba Cloud (Apache 2.0 License).

## License
MIT (c) 2026 David Jeřela
