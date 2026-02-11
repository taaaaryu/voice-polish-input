# VoicePolishInput

Push-to-talk speech → live draft → (stop) polish → insert into the currently focused text field.

## What it does

- `Control + Option + Space` toggles recording (global hotkey).
- While recording, shows a live draft in the menubar popover.
- When you stop, it polishes the text (rule-based by default) and inserts it into the currently focused input field.

## Permissions (macOS)

You’ll need to allow:

- Microphone
- Speech Recognition
- Accessibility (to insert into the focused field)
- Input Monitoring (only if you enable the “type via key events” fallback)

## About the Dictation key (Fn Fn)

macOS’s built-in Dictation key behavior isn’t reliably interceptable by third-party apps.
If you really want to use that key, a practical approach is to remap it to `Control + Option + Space` with a key remapper (e.g. Karabiner-Elements).

## Apple on-device LLM polishing (Foundation Models)

This repo includes an optional on-device polisher behind a build flag:

- Define `ENABLE_FOUNDATION_MODELS`

It requires an SDK that provides `FoundationModels` (macOS 26 SDK / Xcode 26) and Apple Intelligence enabled on the device.

## SpeechAnalyzer transcription

SpeechAnalyzer is also behind a build flag:

- Define `ENABLE_SPEECH_ANALYZER`

The current `SpeechAnalyzerTranscriber` file is a placeholder; it’s intended to be implemented using the macOS 26 Speech APIs (SpeechAnalyzer + SpeechTranscriber).

## Build

From the repo root:

```sh
swift build
```

