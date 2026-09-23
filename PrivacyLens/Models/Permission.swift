import Foundation

/// A macOS privacy permission (TCC service) that PrivacyLens tracks.
enum PermissionService: String, CaseIterable, Identifiable, Hashable {
    case fullDiskAccess
    case camera
    case microphone
    case screenRecording
    case accessibility
    case location
    case contacts
    case calendar
    case reminders
    case photos
    case desktopFolder
    case documentsFolder
    case downloadsFolder
    case networkVolumes
    case removableVolumes

    var id: String { rawValue }

    /// The subset shown as glanceable chips in the app list.
    static let notable: [PermissionService] = [
        .fullDiskAccess, .camera, .microphone, .screenRecording, .accessibility, .location,
    ]

    var displayName: String {
        switch self {
        case .fullDiskAccess: return "Full Disk Access"
        case .camera: return "Camera"
        case .microphone: return "Microphone"
        case .screenRecording: return "Screen Recording"
        case .accessibility: return "Accessibility"
        case .location: return "Location Services"
        case .contacts: return "Contacts"
        case .calendar: return "Calendars"
        case .reminders: return "Reminders"
        case .photos: return "Photos"
        case .desktopFolder: return "Desktop Folder"
        case .documentsFolder: return "Documents Folder"
        case .downloadsFolder: return "Downloads Folder"
        case .networkVolumes: return "Network Volumes"
        case .removableVolumes: return "Removable Volumes"
        }
    }

    var symbolName: String {
        switch self {
        case .fullDiskAccess: return "internaldrive"
        case .camera: return "camera"
        case .microphone: return "mic"
        case .screenRecording: return "display"
        case .accessibility: return "accessibility"
        case .location: return "location"
        case .contacts: return "person.text.rectangle"
        case .calendar: return "calendar"
        case .reminders: return "checklist"
        case .photos: return "photo"
        case .desktopFolder: return "desktopcomputer"
        case .documentsFolder: return "doc"
        case .downloadsFolder: return "arrow.down.circle"
        case .networkVolumes: return "network"
        case .removableVolumes: return "externaldrive"
        }
    }

    /// Key used in the TCC database (`access.service` column).
    var tccServiceKey: String {
        switch self {
        case .fullDiskAccess: return "kTCCServiceSystemPolicyAllFiles"
        case .camera: return "kTCCServiceCamera"
        case .microphone: return "kTCCServiceMicrophone"
        case .screenRecording: return "kTCCServiceScreenCapture"
        case .accessibility: return "kTCCServiceAccessibility"
        case .location: return "kTCCServiceLocation"
        case .contacts: return "kTCCServiceContacts"
        case .calendar: return "kTCCServiceCalendar"
        case .reminders: return "kTCCServiceReminders"
        case .photos: return "kTCCServicePhotos"
        case .desktopFolder: return "kTCCServiceSystemPolicyDesktopFolder"
        case .documentsFolder: return "kTCCServiceSystemPolicyDocumentsFolder"
        case .downloadsFolder: return "kTCCServiceSystemPolicyDownloadsFolder"
        case .networkVolumes: return "kTCCServiceSystemPolicyNetworkVolumes"
        case .removableVolumes: return "kTCCServiceSystemPolicyRemovableVolumes"
        }
    }

    /// Anchor for `x-apple.systempreferences:` deep links into
    /// System Settings → Privacy & Security. Unknown anchors fall back to the
    /// Privacy & Security root pane (graceful degradation).
    var settingsAnchor: String {
        switch self {
        case .fullDiskAccess: return "Privacy_AllFiles"
        case .camera: return "Privacy_Camera"
        case .microphone: return "Privacy_Microphone"
        case .screenRecording: return "Privacy_ScreenCapture"
        case .accessibility: return "Privacy_Accessibility"
        case .location: return "Privacy_LocationServices"
        case .contacts: return "Privacy_Contacts"
        case .calendar: return "Privacy_Calendars"
        case .reminders: return "Privacy_Reminders"
        case .photos: return "Privacy_Photos"
        case .desktopFolder, .documentsFolder, .downloadsFolder, .networkVolumes, .removableVolumes:
            return "Privacy_FilesAndFolders"
        }
    }
}

/// The current permission state for one app.
enum PermissionStatus: Hashable {
    case authorized
    case denied
    case notRequested
    case unknown
}
