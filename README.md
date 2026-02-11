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

This repo will automatically use Apple’s on-device model when the build environment provides `FoundationModels`
(macOS 26 SDK / Xcode 26) and Apple Intelligence is enabled on the device.

## SpeechAnalyzer transcription

This repo will automatically prefer `SpeechAnalyzer` + `SpeechTranscriber` when built with a macOS 26 SDK / Xcode 26.
Otherwise it falls back to `SFSpeechRecognizer`.

## Build

From the repo root:

```sh
swift build
```

If `xcode-select` is still pointing to Command Line Tools, run with:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build
```
