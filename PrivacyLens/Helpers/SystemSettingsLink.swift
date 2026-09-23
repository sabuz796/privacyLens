import AppKit

/// Deep links into System Settings → Privacy & Security via
/// `x-apple.systempreferences:` URLs (the official URL scheme Apple exposes).
enum SystemSettingsLink {
    static func openPrivacyPane(for service: PermissionService) {
        open("com.apple.preference.security?\(service.settingsAnchor)")
    }

    private static func open(_ anchor: String) {
        guard let url = URL(string: "x-apple.systempreferences:\(anchor)") else { return }
        NSWorkspace.shared.open(url)
    }
}
