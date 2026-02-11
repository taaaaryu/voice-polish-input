import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var controller: VoicePolishController

    var body: some View {
        Form {
            Section("Hotkey") {
                Toggle("Enable global hotkey", isOn: $controller.isHotkeyEnabled)
                Text("Default: Control + Option + Space")
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
        .padding(12)
    }
}

