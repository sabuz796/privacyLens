import SwiftUI

extension PermissionStatus {
    /// Symbol + color redundancy so status never relies on color alone
    /// (HIG Accessibility › Vision).
    var label: String {
        switch self {
        case .authorized: return "Granted"
        case .denied: return "Denied"
        case .notRequested: return "Not Requested"
        case .unknown: return "Unknown"
        }
    }

    var symbolName: String {
        switch self {
        case .authorized: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notRequested: return "minus.circle"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .authorized: return .green
        case .denied: return .red
        case .notRequested: return .gray
        case .unknown: return .orange
        }
    }

    /// "Granted · 3 months ago" when a timestamp is known.
    func caption(timestamp: Date?) -> String {
        guard let timestamp else { return label }
        return "\(label) · \(Self.relativeFormatter.localizedString(for: timestamp, relativeTo: Date()))"
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = RelativeDateTimeFormatter()
}

extension RiskLevel {
    var tint: Color {
        switch self {
        case .none: return .gray
        case .elevated: return .orange
        case .high: return .red
        }
    }
}
