import Foundation

/// Persisted user preferences (backed by UserDefaults).
final class Settings {
    static let shared = Settings()
    private let defaults = UserDefaults.standard

    static let defaultZones = ["America/Los_Angeles", "Asia/Shanghai"]

    /// All zones shown in the dropdown, in order.
    var zones: [String] {
        get {
            let stored = defaults.stringArray(forKey: "zones") ?? Settings.defaultZones
            return stored.filter { TimeZone(identifier: $0) != nil }
        }
        set { defaults.set(newValue, forKey: "zones") }
    }

    /// The zone shown in the menu bar itself.
    var primary: String {
        get {
            let p = defaults.string(forKey: "primary") ?? "America/Los_Angeles"
            return zones.contains(p) ? p : (zones.first ?? TimeZone.current.identifier)
        }
        set { defaults.set(newValue, forKey: "primary") }
    }

    var use24Hour: Bool {
        get { defaults.object(forKey: "use24Hour") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "use24Hour") }
    }

    var showSeconds: Bool {
        get { defaults.object(forKey: "showSeconds") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "showSeconds") }
    }

    var showCity: Bool {
        get { defaults.object(forKey: "showCity") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "showCity") }
    }
}
