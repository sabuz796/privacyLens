import SwiftUI

/// Shown while the system TCC database can't be read: explains why Full Disk
/// Access is needed and deep-links to the correct pane. The view model polls
/// in the background and loads real data the moment access is granted.
struct FDARequiredView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.shield")
                .font(.system(size: 52))
                .foregroundStyle(.orange)

            VStack(spacing: 6) {
                Text("Full Disk Access Needed")
                    .font(.title2.weight(.semibold))
                Text("PrivacyLens shows permissions by reading Apple's privacy database (TCC.db). macOS protects that database behind Full Disk Access — grant it so PrivacyLens can report each app's permissions. Everything stays on this Mac.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 440)
            }

            Button {
                SystemSettingsLink.openPrivacyPane(for: .fullDiskAccess)
            } label: {
                Label("Open Full Disk Access Settings", systemImage: "arrow.up.right.square")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("In System Settings, enable PrivacyLens under Full Disk Access (or add it with +). This window refreshes automatically once access is granted.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}
