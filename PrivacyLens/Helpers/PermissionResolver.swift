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

    static func resolve(for app: InstalledApp,
                        records: [TCCRecord],
                        locationClients: [String: PermissionStatus]) -> ResolvedPermissions {
        var resolved = ResolvedPermissions()
        let mine = Dictionary(grouping: records.filter { isClient($0.client, of: app) }, by: \.service)

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
            } else if service == .location, let locationStatus = locationClients[app.bundleID] {
                resolved.statuses[service] = locationStatus
            } else {
                resolved.statuses[service] = .notRequested
            }
        }
        return resolved
    }

    /// A TCC row belongs to this app if the client is its bundle ID — or, for
    /// services that record an executable/bundle path instead, if it lives
    /// inside this app's bundle. The path form also stops an impostor app
    /// from inheriting permissions recorded under another app's bundle path.
    /// (A bundle-ID client string can still be claimed by an impostor's
    /// Info.plist — inherent TCC limitation, documented in the README.)
    static func isClient(_ client: String, of app: InstalledApp) -> Bool {
        client == app.bundleID || client.hasPrefix(app.path.path + "/")
    }
}
