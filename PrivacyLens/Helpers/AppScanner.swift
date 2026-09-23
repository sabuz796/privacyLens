import Foundation

/// Scans well-known application directories for installed apps.
enum AppScanner {
    private static var directories: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let roots = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            home.appendingPathComponent("Applications"),
        ]
        // Utilities live one level below the system roots.
        return roots.flatMap { [$0, $0.appendingPathComponent("Utilities")] }
    }

    static func scanInstalledApps() -> [InstalledApp] {
        var byBundleID: [String: InstalledApp] = [:]
        let ownBundleID = Bundle.main.bundleIdentifier

        for directory in directories {
            let contents = (try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles])) ?? []

            for url in contents where url.pathExtension == "app" {
                guard let app = makeApp(from: url), app.bundleID != ownBundleID else { continue }
                if byBundleID[app.bundleID] == nil {
                    byBundleID[app.bundleID] = app // first directory wins
                }
            }
        }

        return byBundleID.values.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private static func makeApp(from url: URL) -> InstalledApp? {
        guard let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier, !bundleID.isEmpty else { return nil }

        let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent

        return InstalledApp(bundleID: bundleID, name: name, path: url)
    }
}
