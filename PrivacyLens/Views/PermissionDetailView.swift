import SwiftUI

/// Per-app permission list. Clicking any row deep-links into the matching
/// System Settings → Privacy & Security pane.
struct PermissionDetailView: View {
    let entry: AppEntry

    var body: some View {
        List {
            Section {
                header
                    .listRowSeparator(.hidden)
            }
            Section {
                ForEach(PermissionService.allCases) { service in
                    PermissionRowView(
                        service: service,
                        status: entry.statuses[service] ?? .unknown,
                        timestamp: entry.permissions.timestamps[service]
                    )
                }
            } header: {
                Text("Privacy Permissions")
            } footer: {
                Text("Click a permission to open its pane in System Settings → Privacy & Security. Statuses are matched by each app's declared bundle identifier.")
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .navigationTitle(entry.app.name)
    }

    private var header: some View {
        HStack(spacing: 14) {
            AppIconView(path: entry.app.path)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.app.name)
                    .font(.title2.weight(.semibold))
                Text(entry.app.bundleID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                if entry.riskLevel != .none {
                    HStack(spacing: 4) {
                        Image(systemName: entry.riskLevel.symbolName)
                        Text(entry.riskLevel.label)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(entry.riskLevel.tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(entry.riskLevel.tint.opacity(0.12), in: Capsule())
                    .help("This app holds a powerful combination of permissions.")
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.grantedCount)")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.green)
                Text("granted")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

/// One permission row, clickable → System Settings.
struct PermissionRowView: View {
    let service: PermissionService
    let status: PermissionStatus
    var timestamp: Date?

    @State private var isHovering = false

    var body: some View {
        Button {
            SystemSettingsLink.openPrivacyPane(for: service)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: service.symbolName)
                    .frame(width: 22)
                    .foregroundStyle(status.tint)

                VStack(alignment: .leading, spacing: 1) {
                    Text(service.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(status.caption(timestamp: timestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusBadge(status: status)

                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(isHovering ? Color.accentColor : Color(nsColor: .quaternaryLabelColor))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel("\(service.displayName): \(status.caption(timestamp: timestamp))")
        .accessibilityHint("Opens the matching pane in System Settings.")
    }
}

struct StatusBadge: View {
    let status: PermissionStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.symbolName)
                .imageScale(.small)
            Text(status.label)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(status.tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(status.tint.opacity(0.12), in: Capsule())
    }
}
