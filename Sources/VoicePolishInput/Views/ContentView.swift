import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var controller: VoicePolishController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(controller.isRecording ? "Stop" : "Record") {
                    controller.toggleRecording()
                }
                .keyboardShortcut(.space, modifiers: [.command])

                Spacer()

                if controller.isRecording {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            GroupBox("Draft (live)") {
                TextEditor(text: $controller.draftText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 120)
                    .disabled(true)
            }

            GroupBox("Final (polished)") {
                TextEditor(text: $controller.finalText)
                    .font(.body)
                    .frame(minHeight: 120)
                    .disabled(true)
            }

            HStack {
                Button("Insert into focused field") {
                    controller.insertFinalTextIntoFocusedField()
                }
                .disabled(controller.finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()

                if let error = controller.lastError {
                    Text(error)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
    }
}

