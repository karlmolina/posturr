import Foundation

// MARK: - Settings Storage

class SettingsStorage {
    var sensitivity: CGFloat = 0.85
    var deadZone: CGFloat = 0.03
    var useCompatibilityMode = false
    var blurWhenAway = false
    var showInDock = false
    var pauseOnTheGo = false
    var selectedCameraID: String?

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(sensitivity, forKey: SettingsKeys.sensitivity)
        defaults.set(deadZone, forKey: SettingsKeys.deadZone)
        defaults.set(useCompatibilityMode, forKey: SettingsKeys.useCompatibilityMode)
        defaults.set(blurWhenAway, forKey: SettingsKeys.blurWhenAway)
        defaults.set(showInDock, forKey: SettingsKeys.showInDock)
        defaults.set(pauseOnTheGo, forKey: SettingsKeys.pauseOnTheGo)
        if let cameraID = selectedCameraID {
            defaults.set(cameraID, forKey: SettingsKeys.lastCameraID)
        }
    }

    func load() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: SettingsKeys.sensitivity) != nil {
            sensitivity = defaults.double(forKey: SettingsKeys.sensitivity)
        }
        if defaults.object(forKey: SettingsKeys.deadZone) != nil {
            deadZone = defaults.double(forKey: SettingsKeys.deadZone)
        }
        useCompatibilityMode = defaults.bool(forKey: SettingsKeys.useCompatibilityMode)
        blurWhenAway = defaults.bool(forKey: SettingsKeys.blurWhenAway)
        showInDock = defaults.bool(forKey: SettingsKeys.showInDock)
        pauseOnTheGo = defaults.bool(forKey: SettingsKeys.pauseOnTheGo)
        selectedCameraID = defaults.string(forKey: SettingsKeys.lastCameraID)
    }
}

// MARK: - Profile Storage

class ProfileStorage {
    func saveProfile(forKey key: String, data: ProfileData) {
        let defaults = UserDefaults.standard
        var profiles = defaults.dictionary(forKey: SettingsKeys.profiles) as? [String: Data] ?? [:]

        if let encoded = try? JSONEncoder().encode(data) {
            profiles[key] = encoded
            defaults.set(profiles, forKey: SettingsKeys.profiles)
        }
    }

    func loadProfile(forKey key: String) -> ProfileData? {
        let defaults = UserDefaults.standard
        guard let profiles = defaults.dictionary(forKey: SettingsKeys.profiles) as? [String: Data],
              let data = profiles[key] else {
            return nil
        }

        return try? JSONDecoder().decode(ProfileData.self, from: data)
    }

    func deleteProfile(forKey key: String) {
        let defaults = UserDefaults.standard
        var profiles = defaults.dictionary(forKey: SettingsKeys.profiles) as? [String: Data] ?? [:]
        profiles.removeValue(forKey: key)
        defaults.set(profiles, forKey: SettingsKeys.profiles)
    }
}
