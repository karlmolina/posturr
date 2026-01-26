import AppKit
import SwiftUI

// MARK: - Settings Window Controller

class SettingsWindowController: NSObject, NSWindowDelegate {
    var window: NSWindow?
    weak var appDelegate: AppDelegate?

    func showSettings(appDelegate: AppDelegate, fromStatusItem statusItem: NSStatusItem?) {
        self.appDelegate = appDelegate

        // Find the screen where the status item is located
        let targetScreen = statusItem?.button?.window?.screen ?? NSScreen.main ?? NSScreen.screens.first

        if let existingWindow = window {
            // Move existing window to the correct screen and center it
            if let screen = targetScreen {
                centerWindow(existingWindow, on: screen)
            }
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(appDelegate: appDelegate)
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 580, height: 320),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Posturr Settings"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.delegate = self

        // Center on the target screen
        if let screen = targetScreen {
            centerWindow(window, on: screen)
        } else {
            window.center()
        }

        self.window = window
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        // Only hide from Dock if user hasn't enabled "Show in Dock"
        if let appDelegate = appDelegate, !appDelegate.showInDock {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func centerWindow(_ window: NSWindow, on screen: NSScreen) {
        let screenFrame = screen.frame
        let windowSize = window.frame.size
        let x = screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2
        let y = screenFrame.origin.y + (screenFrame.height - windowSize.height) / 2
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func close() {
        window?.close()
    }
}

// MARK: - Setting Toggle Component

struct SettingToggle: View {
    let title: String
    @Binding var isOn: Bool
    let helpText: String
    @State private var showingHelp = false

    var body: some View {
        HStack {
            Toggle(title, isOn: $isOn)
            Button(action: { showingHelp.toggle() }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingHelp, arrowEdge: .trailing) {
                Text(helpText)
                    .padding(10)
                    .frame(width: 200)
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    let appDelegate: AppDelegate

    // Local state that syncs with AppDelegate
    @State private var sensitivity: Double = 0.85
    @State private var deadZone: Double = 0.03
    @State private var sensitivitySlider: Double = 2
    @State private var deadZoneSlider: Double = 2
    @State private var blurWhenAway: Bool = false
    @State private var showInDock: Bool = false
    @State private var pauseOnTheGo: Bool = false
    @State private var useCompatibilityMode: Bool = false
    @State private var selectedCameraID: String = ""
    @State private var availableCameras: [(id: String, name: String)] = []

    let sensitivityOptions: [(label: String, value: Double, description: String)] = [
        ("Very Low", 0.4, "Only major slouching"),
        ("Low", 0.6, "Allows more movement"),
        ("Medium", 0.85, "Balanced"),
        ("High", 0.95, "Reacts to small changes"),
        ("Very High", 1.0, "Maximum response")
    ]

    let deadZoneOptions: [(label: String, value: Double, description: String)] = [
        ("Very Small", 0.01, "Activates immediately"),
        ("Small", 0.02, "Strict enforcement"),
        ("Medium", 0.03, "Balanced"),
        ("Large", 0.05, "Allows natural movement"),
        ("Very Large", 0.08, "Only major slouching")
    ]

    let sensitivityValues: [Double] = [0.4, 0.6, 0.85, 0.95, 1.0]
    let sensitivityLabels = ["Very Low", "Low", "Medium", "High", "Very High"]

    let deadZoneValues: [Double] = [0.01, 0.02, 0.03, 0.05, 0.08]
    let deadZoneLabels = ["Very Small", "Small", "Medium", "Large", "Very Large"]

    var sensitivityIndex: Int {
        sensitivityValues.firstIndex(of: sensitivity) ?? 2
    }

    var deadZoneIndex: Int {
        deadZoneValues.firstIndex(of: deadZone) ?? 2
    }

    var sensitivityLabel: String {
        sensitivityLabels[sensitivityIndex]
    }

    var deadZoneLabel: String {
        deadZoneLabels[deadZoneIndex]
    }

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Left column - Detection settings
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Camera") {
                    Picker("", selection: $selectedCameraID) {
                        ForEach(availableCameras, id: \.id) { camera in
                            Text(camera.name).tag(camera.id)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: selectedCameraID) { newValue in
                        if newValue != appDelegate.selectedCameraID {
                            appDelegate.selectedCameraID = newValue
                            appDelegate.saveSettings()
                            appDelegate.restartCamera()
                        }
                    }
                }

                GroupBox("Sensitivity") {
                    VStack(alignment: .leading, spacing: 8) {
                        Slider(value: $sensitivitySlider, in: 0...4, step: 1)
                            .onChange(of: sensitivitySlider) { newValue in
                                let index = Int(newValue)
                                sensitivity = sensitivityValues[index]
                                appDelegate.sensitivity = sensitivity
                                appDelegate.saveSettings()
                            }
                        HStack {
                            Text("Low")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(sensitivityLabels[Int(sensitivitySlider)])
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                            Text("High")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                GroupBox("Dead Zone") {
                    VStack(alignment: .leading, spacing: 8) {
                        Slider(value: $deadZoneSlider, in: 0...4, step: 1)
                            .onChange(of: deadZoneSlider) { newValue in
                                let index = Int(newValue)
                                deadZone = deadZoneValues[index]
                                appDelegate.deadZone = deadZone
                                appDelegate.saveSettings()
                            }
                        HStack {
                            Text("Small")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(deadZoneLabels[Int(deadZoneSlider)])
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                            Text("Large")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(width: 240)

            // Right column - Behavior toggles
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Behavior") {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingToggle(
                            title: "Blur when away",
                            isOn: $blurWhenAway,
                            helpText: "Apply full blur when you step away from the screen"
                        )
                        .onChange(of: blurWhenAway) { newValue in
                            appDelegate.blurWhenAway = newValue
                            appDelegate.saveSettings()
                            if !newValue {
                                appDelegate.consecutiveNoDetectionFrames = 0
                            }
                        }

                        Divider()

                        SettingToggle(
                            title: "Show in dock",
                            isOn: $showInDock,
                            helpText: "Keep Posturr visible in the Dock and Cmd+Tab switcher"
                        )
                        .onChange(of: showInDock) { newValue in
                            appDelegate.showInDock = newValue
                            appDelegate.saveSettings()
                            // Change policy but keep settings window open
                            NSApp.setActivationPolicy(newValue ? .regular : .accessory)
                            // Re-activate to keep window visible
                            DispatchQueue.main.async {
                                appDelegate.settingsWindowController.window?.makeKeyAndOrderFront(nil)
                                NSApp.activate(ignoringOtherApps: true)
                            }
                        }

                        Divider()

                        SettingToggle(
                            title: "Pause on the go",
                            isOn: $pauseOnTheGo,
                            helpText: "Auto-pause when laptop display becomes the only screen"
                        )
                        .onChange(of: pauseOnTheGo) { newValue in
                            appDelegate.pauseOnTheGo = newValue
                            appDelegate.saveSettings()
                            if !newValue && appDelegate.state == .paused(.onTheGo) {
                                appDelegate.state = .monitoring
                            }
                        }
                    }
                }

                #if !APP_STORE
                GroupBox("Advanced") {
                    SettingToggle(
                        title: "Compatibility mode",
                        isOn: $useCompatibilityMode,
                        helpText: "Enable if blur isn't appearing. Uses alternative rendering method."
                    )
                    .onChange(of: useCompatibilityMode) { newValue in
                        appDelegate.useCompatibilityMode = newValue
                        appDelegate.saveSettings()
                        appDelegate.currentBlurRadius = 0
                        for blurView in appDelegate.blurViews {
                            blurView.alphaValue = 0
                        }
                    }
                }
                #endif

                Spacer()
            }
            .frame(width: 280)
        }
        .padding(20)
        .onAppear {
            loadFromAppDelegate()
        }
    }

    private func loadFromAppDelegate() {
        sensitivity = appDelegate.sensitivity
        deadZone = appDelegate.deadZone
        blurWhenAway = appDelegate.blurWhenAway
        showInDock = appDelegate.showInDock
        pauseOnTheGo = appDelegate.pauseOnTheGo
        useCompatibilityMode = appDelegate.useCompatibilityMode

        // Set slider indices based on loaded values
        sensitivitySlider = Double(sensitivityValues.firstIndex(of: sensitivity) ?? 2)
        deadZoneSlider = Double(deadZoneValues.firstIndex(of: deadZone) ?? 2)

        // Load cameras
        let cameras = appDelegate.getAvailableCameras()
        availableCameras = cameras.map { (id: $0.uniqueID, name: $0.localizedName) }
        selectedCameraID = appDelegate.selectedCameraID ?? cameras.first?.uniqueID ?? ""
    }
}
