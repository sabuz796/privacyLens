import Foundation

extension Notification.Name {
    static let privacyLensRefreshRequested = Notification.Name("PrivacyLensRefreshRequested")
}

/// Owns the app list, permission statuses, and the Full Disk Access state.
///
/// RAM/CPU budget: background monitoring is one `stat` per 15 s; a full
/// rescan (directory walk + SQLite reads, off the main thread) happens only
/// when the TCC database actually changed on disk or the user asks for it.
@MainActor
final class AppListViewModel: ObservableObject {
    @Published private(set) var entries: [AppEntry] = []
    @Published private(set) var hasFullDiskAccess = TCCDatabase.hasFullDiskAccess
    @Published private(set) var isLoading = false
    /// Drives the "list updated" toast after a background change.
    @Published var changeAnnouncement: String?

    private var fdaPollTask: Task<Void, Never>?
    private var toastDismissTask: Task<Void, Never>?
    private var tccPollTimer: Timer?
    private var refreshObserver: NSObjectProtocol?
    private var lastKnownModification: Date?

    init() {
        refreshObserver = NotificationCenter.default.addObserver(
            forName: .privacyLensRefreshRequested, object: nil, queue: .main
        ) { [weak self] _ in
            Task { await self?.refresh() }
        }
        startTCCPolling()
        Task { await refresh() }
    }

    deinit {
        if let refreshObserver { NotificationCenter.default.removeObserver(refreshObserver) }
        fdaPollTask?.cancel()
        toastDismissTask?.cancel()
        tccPollTimer?.invalidate()
    }

    func filteredEntries(matching searchText: String, withFilter filter: PermissionService?) -> [AppEntry] {
        var result = entries
        if let filter {
            result = result.filter { $0.statuses[filter] == .authorized }
        }
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.app.name.lowercased().contains(query) || $0.app.bundleID.lowercased().contains(query)
            }
        }
        return result
    }

    /// Called when the window becomes key — cheap dedup: rescans only if
    /// the TCC database actually changed since the last load.
    func refreshIfTCCChanged() {
        guard hasFullDiskAccess, !isLoading,
              let modified = TCCDatabase.modificationDate,
              modified != lastKnownModification else { return }
        Task { await refresh(announceChange: true) }
    }

    func refresh() async {
        await refresh(announceChange: false)
    }

    private func refresh(announceChange: Bool) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        // Heavy work off the main thread: directory scans + SQLite reads.
        let snapshot = await Task.detached(priority: .userInitiated) { () -> ([InstalledApp], [TCCRecord], [String: PermissionStatus]) in
            (
                AppScanner.scanInstalledApps(),
                TCCDatabase.fetchRecords(),
                TCCDatabase.locationClientAuthorization()
            )
        }.value

        let (apps, records, locationClients) = snapshot
        hasFullDiskAccess = TCCDatabase.hasFullDiskAccess
        lastKnownModification = TCCDatabase.modificationDate

        entries = apps.map { app in
            let permissions: ResolvedPermissions
            if hasFullDiskAccess {
                permissions = PermissionResolver.resolve(
                    for: app,
                    records: records,
                    locationClients: locationClients
                )
            } else {
                // Without Full Disk Access there is no data; the UI explains what to grant.
                permissions = ResolvedPermissions()
            }
            return AppEntry(app: app, permissions: permissions)
        }

        if announceChange {
            changeAnnouncement = "Permissions changed — list updated"
            toastDismissTask?.cancel()
            toastDismissTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { return }
                self?.changeAnnouncement = nil
            }
        }

        startFDAPollingIfNeeded()
    }

    /// Live monitoring: one `stat` every 15 s — negligible cost. The moment
    /// TCC.db's modification date moves, the list rescans and a toast appears.
    private func startTCCPolling() {
        guard tccPollTimer == nil else { return }
        let timer = Timer(timeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshIfTCCChanged()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        tccPollTimer = timer
    }

    /// While Full Disk Access is missing, poll quietly — the moment the user
    /// flips the toggle in System Settings, load the real data.
    private func startFDAPollingIfNeeded() {
        guard !hasFullDiskAccess, fdaPollTask == nil else { return }
        fdaPollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard let self else { return }
                let granted = TCCDatabase.hasFullDiskAccess
                if granted != self.hasFullDiskAccess {
                    self.hasFullDiskAccess = granted
                    if granted {
                        self.fdaPollTask?.cancel()
                        self.fdaPollTask = nil
                        await self.refresh()
                    }
                }
            }
        }
    }
}
