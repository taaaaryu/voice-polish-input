import AppKit
import SwiftUI

@main
struct VoicePolishInputApp: App {
    @StateObject private var controller = VoicePolishController()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("VoicePolishInput", systemImage: controller.isRecording ? "mic.fill" : "mic") {
            ContentView()
                .environmentObject(controller)
                .frame(width: 420)
        }

        Settings {
            SettingsView()
                .environmentObject(controller)
                .frame(width: 700, height: 560)
        }
    }
}
