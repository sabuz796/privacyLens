import SwiftUI

@main
struct PrivacyLensApp: App {
    #if DEBUG
    init() {
        Self.debugSelfCheck()
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Refresh Permissions") {
                    NotificationCenter.default.post(name: .privacyLensRefreshRequested, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }

    #if DEBUG
    /// ponytail: the one runnable check — keeps the service → TCC key /
    /// settings anchor mapping honest. Fails the Debug build if they drift.
    static func debugSelfCheck() {
        for service in PermissionService.allCases {
            assert(!service.displayName.isEmpty, "missing displayName for \(service)")
            assert(!service.symbolName.isEmpty, "missing symbol for \(service)")
            assert(!service.settingsAnchor.isEmpty, "missing settings anchor for \(service)")
            assert(service.tccServiceKey.hasPrefix("kTCCService"), "bad TCC key for \(service)")
        }
        let keys = Set(PermissionService.allCases.map(\.tccServiceKey))
        assert(keys.count == PermissionService.allCases.count, "duplicate TCC service keys")
    }
    #endif
}
