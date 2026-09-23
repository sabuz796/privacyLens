import SwiftUI

/// Sidebar row: icon, name, risk badge, and the signature permission chips.
struct AppRowView: View {
    let entry: AppEntry

    var body: some View {
        HStack(spacing: 10) {
            AppIconView(path: entry.app.path)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.app.name)
                    .font(.body)
                    .lineLimit(1)
                Text(entry.app.bundleID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            if entry.riskLevel != .none {
                Image(systemName: entry.riskLevel.symbolName)
                    .font(.system(size: 11))
                    .foregroundStyle(entry.riskLevel.tint)
                    .help(entry.riskLevel.label)
            }

            PermissionChipsView(entry: entry)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.app.name), \(entry.grantedCount) permissions granted\(entry.riskLevel == .none ? "" : ", \(entry.riskLevel.label)")")
    }
}

/// Signature element: mini shield-style glyphs for the sensitive permissions
/// an app currently holds, plus a granted count.
struct PermissionChipsView: View {
    let entry: AppEntry

    var body: some View {
        HStack(spacing: 3) {
            ForEach(PermissionService.notable, id: \.self) { service in
                if entry.statuses[service] == .authorized {
                    Image(systemName: service.symbolName)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.green)
                        .help("\(service.displayName): Granted")
                }
            }
            if !entry.statuses.isEmpty {
                Text("\(entry.grantedCount)")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.quaternary, in: Capsule())
                    .help("Permissions granted")
            }
        }
    }
}

/// Cached-by-the-system app icon.
struct AppIconView: View {
    let path: URL

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: path.path))
            .resizable()
            .interpolation(.high)
    }
}
