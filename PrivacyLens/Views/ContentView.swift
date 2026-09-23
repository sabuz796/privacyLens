import SwiftUI

/// Sidebar (searchable, filterable app list) + detail (per-app permission rows).
struct ContentView: View {
    @StateObject private var viewModel = AppListViewModel()
    @State private var searchText = ""
    @State private var selection: String?
    @State private var permissionFilter: PermissionService?

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .frame(minWidth: 860, minHeight: 540)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.refreshIfTCCChanged()
        }
    }

    private var filteredEntries: [AppEntry] {
        viewModel.filteredEntries(matching: searchText, withFilter: permissionFilter)
    }

    private var sidebar: some View {
        List(selection: $selection) {
            ForEach(filteredEntries) { entry in
                AppRowView(entry: entry)
                    .tag(entry.id)
                    .contextMenu {
                        Button("Reveal in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([entry.app.path])
                        }
                        Button("Open \(entry.app.name)") {
                            Task {
                                try? await NSWorkspace.shared.openApplication(
                                    at: entry.app.path,
                                    configuration: NSWorkspace.OpenConfiguration()
                                )
                            }
                        }
                    }
            }
        }
        .listStyle(.sidebar)
        .overlay {
            if viewModel.entries.isEmpty {
                if viewModel.isLoading {
                    ProgressView("Scanning applications…")
                } else {
                    ContentUnavailableView("No Apps Found", systemImage: "app.dashed")
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            FilterChipsView(selected: $permissionFilter)
                .background(.ultraThinMaterial)
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search apps or bundle IDs")
        .navigationSplitViewColumnWidth(min: 260, ideal: 310, max: 400)
    }

    @ViewBuilder
    private var detail: some View {
        Group {
            if !viewModel.hasFullDiskAccess {
                FDARequiredView()
            } else if let entry = filteredEntries.first(where: { $0.id == selection }) ?? filteredEntries.first {
                PermissionDetailView(entry: entry)
            } else {
                ContentUnavailableView(
                    "Select an App",
                    systemImage: "shield.lefthalf.filled",
                    description: Text("Choose an app to inspect its privacy permissions.")
                )
            }
        }
        .toolbar { ToolbarItem(placement: .primaryAction) { refreshButton } }
        .overlay(alignment: .top) {
            if let announcement = viewModel.changeAnnouncement {
                ToastView(text: announcement)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: viewModel.changeAnnouncement)
    }

    private var refreshButton: some View {
        Button {
            Task { await viewModel.refresh() }
        } label: {
            if viewModel.isLoading {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
        .disabled(viewModel.isLoading)
        .help("Refresh permissions (⌘R)")
    }
}

/// Quick filter: show only apps granted a specific sensitive permission.
struct FilterChipsView: View {
    @Binding var selected: PermissionService?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chip("All", service: nil)
                ForEach(PermissionService.notable) { service in
                    chip(service.displayName, service: service)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    private func chip(_ title: String, service: PermissionService?) -> some View {
        Button {
            withAnimation(.snappy) { selected = service }
        } label: {
            HStack(spacing: 4) {
                if let service {
                    Image(systemName: service.symbolName)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                selected == service
                    ? Color.accentColor.opacity(0.18)
                    : Color(nsColor: .quaternaryLabelColor).opacity(0.5),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(selected == service ? Color.accentColor : Color.secondary)
        .accessibilityLabel(selected == service ? "\(title) filter, on" : "\(title) filter, off")
    }
}

/// Brief banner confirming a background refresh picked up changes.
struct ToastView: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "arrow.triangle.2.circlepath")
            .font(.callout.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.quaternary))
            .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
    }
}
