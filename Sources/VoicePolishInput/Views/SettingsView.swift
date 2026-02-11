import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var controller: VoicePolishController
    @State private var newFillerWord: String = ""
    @State private var replacementFrom: String = ""
    @State private var replacementTo: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Form {
                    Section("Hotkey") {
                        Toggle("Enable global hotkey", isOn: $controller.isHotkeyEnabled)
                        Text("Default: F5")
                            .foregroundStyle(.secondary)
                    }

                    Section("Polish") {
                        Toggle("Use on-device Apple model (if available)", isOn: $controller.useFoundationModelsWhenAvailable)
                        Text("Requires macOS 26 + Apple Intelligence enabled.")
                            .foregroundStyle(.secondary)
                    }

                    Section("Insert") {
                        Toggle("Type via key events (fallback)", isOn: $controller.typeFallbackEnabled)
                        Text("AX insert is faster, but some apps don’t allow it.")
                            .foregroundStyle(.secondary)
                    }
                }

                GroupBox("Filler Words (remove target words)") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("例: うーん", text: $newFillerWord)
                            Button("Add") {
                                controller.addFillerWord(newFillerWord)
                                newFillerWord = ""
                            }
                            .disabled(newFillerWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        if controller.fillerWords.isEmpty {
                            Text("No filler words.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(controller.fillerWords, id: \.self) { word in
                                HStack {
                                    Text(word)
                                    Spacer()
                                    Button("Remove") {
                                        controller.removeFillerWord(word)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                GroupBox("User Dictionary (replace rules)") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("From", text: $replacementFrom)
                            Text("→")
                            TextField("To", text: $replacementTo)
                            Button("Add") {
                                controller.addReplacement(from: replacementFrom, to: replacementTo)
                                replacementFrom = ""
                                replacementTo = ""
                            }
                            .disabled(
                                replacementFrom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                replacementTo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            )
                        }

                        if controller.replacementEntries.isEmpty {
                            Text("No user dictionary entries.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(controller.replacementEntries, id: \.from) { entry in
                                HStack {
                                    Text(entry.from)
                                    Text("→")
                                    Text(entry.to)
                                    Spacer()
                                    Button("Remove") {
                                        controller.removeReplacement(from: entry.from)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(12)
    }
}
