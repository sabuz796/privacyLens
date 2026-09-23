import Foundation

/// An application installed on this Mac.
struct InstalledApp: Identifiable, Hashable {
    let bundleID: String
    let name: String
    let path: URL

    var id: String { bundleID }
}

/// How dangerous an app's granted-permission combination is.
enum RiskLevel: Comparable, Hashable {
    case none
    case elevated
    case high

    var label: String {
        switch self {
        case .none: return ""
        case .elevated: return "Elevated Access"
        case .high: return "High-Risk Combo"
        }
    }

    var symbolName: String {
        switch self {
        case .none: return ""
        case .elevated: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        }
    }
}

/// Statuses plus when each permission was last modified.
struct ResolvedPermissions: Hashable {
    var statuses: [PermissionService: PermissionStatus] = [:]
    var timestamps: [PermissionService: Date] = [:]
}

/// An installed app together with its resolved permissions.
/// Empty `statuses` means no data could be read (e.g. no Full Disk Access).
struct AppEntry: Identifiable, Hashable {
    let app: InstalledApp
    let permissions: ResolvedPermissions

    var id: String { app.id }

    var statuses: [PermissionService: PermissionStatus] { permissions.statuses }

    var grantedCount: Int {
        statuses.values.filter { $0 == .authorized }.count
    }

    /// Dangerous *combinations* of granted permissions:
    /// Accessibility + Screen Recording = full remote-control capability (high);
    /// any of Accessibility / Screen Recording / Full Disk Access alone (elevated).
    var riskLevel: RiskLevel {
        func granted(_ service: PermissionService) -> Bool {
            statuses[service] == .authorized
        }
        if granted(.accessibility) && granted(.screenRecording) { return .high }
        if granted(.accessibility) || granted(.screenRecording) || granted(.fullDiskAccess) { return .elevated }
        return .none
    }
}
