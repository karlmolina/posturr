import AppKit
import CoreGraphics

// MARK: - Display Manager

class DisplayManager {
    weak var appDelegate: AppDelegate?

    var displayDebounceTimer: Timer?

    func getDisplayUUIDs() -> [String] {
        var uuids: [String] = []

        for screen in NSScreen.screens {
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
                continue
            }

            if let uuid = CGDisplayCreateUUIDFromDisplayID(screenNumber)?.takeRetainedValue() {
                let uuidString = CFUUIDCreateString(nil, uuid) as String
                uuids.append(uuidString)
            }
        }

        return uuids.sorted()
    }

    func buildConfigKey(displayUUIDs: [String]) -> String {
        return "displays:\(displayUUIDs.joined(separator: "+"))"
    }

    func getCurrentConfigKey() -> String {
        let displays = getDisplayUUIDs()
        return buildConfigKey(displayUUIDs: displays)
    }

    func isLaptopOnlyConfiguration() -> Bool {
        let screens = NSScreen.screens
        if screens.count != 1 { return false }

        guard let screen = screens.first,
              let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            return false
        }

        return CGDisplayIsBuiltin(displayID) != 0
    }

    func registerDisplayChangeCallback() {
        let callback: CGDisplayReconfigurationCallBack = { displayID, flags, userInfo in
            guard let userInfo = userInfo else { return }
            let manager = Unmanaged<DisplayManager>.fromOpaque(userInfo).takeUnretainedValue()

            // Only handle when reconfiguration completes
            if flags.contains(.beginConfigurationFlag) {
                return
            }

            manager.scheduleDisplayConfigurationChange()
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        CGDisplayRegisterReconfigurationCallback(callback, userInfo)
    }

    func scheduleDisplayConfigurationChange() {
        // Debounce - displays often send multiple events
        DispatchQueue.main.async { [weak self] in
            self?.displayDebounceTimer?.invalidate()
            self?.displayDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                self?.appDelegate?.handleDisplayConfigurationChange()
            }
        }
    }
}
