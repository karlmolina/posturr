import Foundation
import CoreGraphics

// MARK: - Settings Keys
enum SettingsKeys {
    static let sensitivity = "sensitivity"
    static let deadZone = "deadZone"
    static let useCompatibilityMode = "useCompatibilityMode"
    static let blurWhenAway = "blurWhenAway"
    static let showInDock = "showInDock"
    static let pauseOnTheGo = "pauseOnTheGo"
    static let lastCameraID = "lastCameraID"
    static let profiles = "profiles"
}

// MARK: - Profile Data
struct ProfileData: Codable {
    let goodPostureY: CGFloat
    let badPostureY: CGFloat
    let neutralY: CGFloat
    let postureRange: CGFloat
    let cameraID: String
}

// MARK: - Pause Reason
enum PauseReason: Equatable {
    case noProfile
    case onTheGo
    case cameraDisconnected
}

// MARK: - App State
enum AppState: Equatable {
    case disabled
    case calibrating
    case monitoring
    case paused(PauseReason)

    var isActive: Bool {
        switch self {
        case .monitoring, .calibrating: return true
        case .disabled, .paused: return false
        }
    }
}
