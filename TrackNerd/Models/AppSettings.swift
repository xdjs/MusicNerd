import Foundation

@Observable
class AppSettings {
    static let shared = AppSettings()
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Settings Keys
    private enum Keys {
        static let sampleDuration = "sample_duration"
    }
    
    // MARK: - Sample Duration Setting
    var sampleDuration: TimeInterval {
        get {
            let saved = userDefaults.double(forKey: Keys.sampleDuration)
            return saved > 0 ? saved : 3.0 // Default to 3 seconds
        }
        set {
            userDefaults.set(newValue, forKey: Keys.sampleDuration)
        }
    }
    
    private init() {}
    
    // MARK: - Debug Methods
    
    func resetToDefaults() {
        userDefaults.removeObject(forKey: Keys.sampleDuration)
    }
}

// MARK: - Sample Duration Options
extension AppSettings {
    static let sampleDurationOptions: [TimeInterval] = [3, 5, 10, 15, 20]
    
    static func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        return "\(seconds) second\(seconds == 1 ? "" : "s")"
    }
}