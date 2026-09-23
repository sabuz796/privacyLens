import Foundation

/// Maps TCC database records to per-app permission statuses.
///
/// Apple's public APIs (`AVCaptureDevice.authorizationStatus`,
/// `AXIsProcessTrusted`, `CGPreflightScreenCaptureAccess`, …) only report the
/// *calling* process's own status, so for other apps the TCC database is the
/// only source. When it cannot be read (no Full Disk Access), statuses fall
/// back to empty and the UI explains what to grant.
enum PermissionResolver {
    /// TCC `auth_value`: 2 = allowed, 0 = denied, 1 = legacy one-shot, 3 = limited (Photos).
    static func status(forAuthValue value: Int32) -> PermissionStatus {
        switch value {
        case 2: return .authorized
        case 0: return .denied
        default: return .unknown
        }
    }

    static func resolve(forBundleID bundleID: String,
                        records: [TCCRecord],
                        locationClients: [String: PermissionStatus]) -> ResolvedPermissions {
        var resolved = ResolvedPermissions()
        let mine = Dictionary(grouping: records.filter { $0.client == bundleID }, by: \.service)

        for service in PermissionService.allCases {
            if let rows = mine[service.tccServiceKey] {
                let rowStatuses = rows.map { status(forAuthValue: $0.authValue) }
                if rowStatuses.contains(.authorized) {
                    resolved.statuses[service] = .authorized
                } else if rowStatuses.allSatisfy({ $0 == .denied }) {
                    resolved.statuses[service] = .denied
                } else {
                    resolved.statuses[service] = .unknown
                }
                // Most recent row wins — a permission can be granted, revoked, re-granted.
                resolved.timestamps[service] = rows
                    .compactMap { TCCDatabase.date(fromLastModified: $0.lastModified) }
                    .max()
            } else if service == .location, let locationStatus = locationClients[bundleID] {
                resolved.statuses[service] = locationStatus
            } else {
                resolved.statuses[service] = .notRequested
            }
        }
        return resolved
    }
}
