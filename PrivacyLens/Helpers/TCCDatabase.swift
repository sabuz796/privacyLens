import Foundation
import SQLite3

/// One row of Apple's TCC privacy database.
struct TCCRecord {
    let service: String
    let client: String
    let authValue: Int32
    let lastModified: Int64
}

/// Read-only access to Apple's TCC databases, which record every app's
/// privacy permissions. Reading them requires Full Disk Access.
enum TCCDatabase {
    /// System-wide permissions (Full Disk Access, Accessibility, Screen Recording…).
    static let systemPath = "/Library/Application Support/com.apple.TCC/TCC.db"
    /// User-granted permissions (Camera, Microphone, Contacts…).
    static let userPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")
        .path

    /// Reading the system TCC database is the definitive Full Disk Access test.
    static var hasFullDiskAccess: Bool {
        FileManager.default.isReadableFile(atPath: systemPath)
    }

    /// Newest modification date across both TCC databases — the cheap
    /// (single-`stat`) change signal used for live monitoring.
    static var modificationDate: Date? {
        [systemPath, userPath].compactMap {
            try? FileManager.default.attributesOfItem(atPath: $0)[.modificationDate] as? Date
        }.max()
    }

    /// Reads both databases and merges their rows. An unreadable database
    /// (e.g. no Full Disk Access) simply contributes no records.
    static func fetchRecords() -> [TCCRecord] {
        var records: [TCCRecord] = []
        for path in [systemPath, userPath] where FileManager.default.isReadableFile(atPath: path) {
            records.append(contentsOf: readDatabase(at: path))
        }
        return records
    }

    /// Location permissions live in locationd's registry, not TCC. That file is
    /// world-readable (no Full Disk Access needed) and records, per client:
    ///   `Authorized == true`  → granted
    ///   `Authorized == false` → denied
    ///   no `Authorized` key   → registered with locationd, never decided
    /// Entries marked `SuppressShowingInSettings` are hidden from System
    /// Settings, so they're skipped here too.
    static func locationClientAuthorization() -> [String: PermissionStatus] {
        let path = "/var/db/locationd/clients.plist"
        guard FileManager.default.isReadableFile(atPath: path),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else { return [:] }

        var result: [String: PermissionStatus] = [:]
        for (key, value) in plist {
            guard let entry = value as? [String: Any] else { continue }
            guard entry["SuppressShowingInSettings"] as? Bool != true else { continue }
            guard let bundleID = locationBundleID(key: key, entry: entry) else { continue }

            switch entry["Authorized"] as? Bool {
            case .some(true): result[bundleID] = .authorized
            case .some(false): result[bundleID] = .denied
            case .none: result[bundleID] = .notRequested
            }
        }
        return result
    }

    /// Registry keys look like `<UUID>:<bundle-id>:`, and entries usually carry
    /// an explicit `BundleId` field — prefer that, fall back to the key suffix.
    private static func locationBundleID(key: String, entry: [String: Any]) -> String? {
        if let bundleID = entry["BundleId"] as? String, !bundleID.isEmpty {
            return bundleID
        }
        let parts = key.split(separator: ":")
        guard parts.count >= 2 else { return nil }
        let bundleID = String(parts[1])
        return bundleID.isEmpty ? nil : bundleID
    }

    /// TCC stores `last_modified` as epoch seconds. Different macOS versions
    /// have used Unix epoch (1970) and Apple epoch (2001) — auto-detect:
    /// values ≥ 1e9 can only be Unix; smaller ones are Apple epoch.
    /// Returns nil for unset rows or implausible dates (clock skew).
    static func date(fromLastModified seconds: Int64) -> Date? {
        guard seconds > 0 else { return nil }
        let date = seconds >= 1_000_000_000
            ? Date(timeIntervalSince1970: TimeInterval(seconds))
            : Date(timeIntervalSinceReferenceDate: TimeInterval(seconds))
        return date < Date() && date > Date(timeIntervalSinceReferenceDate: 0) ? date : nil
    }

    private static func readDatabase(at path: String) -> [TCCRecord] {
        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            sqlite3_close(db)
            return []
        }
        defer { sqlite3_close(db) }

        let sql = "SELECT service, client, auth_value, last_modified FROM access"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(statement) }

        var records: [TCCRecord] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let service = stringColumn(statement, 0) ?? ""
            let client = stringColumn(statement, 1) ?? ""
            let authValue = sqlite3_column_int(statement, 2)
            let lastModified = Int64(sqlite3_column_int64(statement, 3))
            records.append(TCCRecord(service: service, client: client, authValue: authValue, lastModified: lastModified))
        }
        return records
    }

    private static func stringColumn(_ statement: OpaquePointer?, _ index: Int32) -> String? {
        guard let cString = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: cString)
    }
}
