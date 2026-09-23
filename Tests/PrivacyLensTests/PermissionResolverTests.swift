import XCTest
@testable import PrivacyLens

final class PermissionResolverTests: XCTestCase {
    private let app = InstalledApp(
        bundleID: "com.example.Foo",
        name: "Foo",
        path: URL(fileURLWithPath: "/Applications/Foo.app")
    )

    private func record(service: String, client: String, auth: Int32) -> TCCRecord {
        TCCRecord(service: service, client: client, authValue: auth, lastModified: 0)
    }

    // MARK: auth_value mapping

    func testAuthValueMapping() {
        XCTAssertEqual(PermissionResolver.status(forAuthValue: 2), .authorized)
        XCTAssertEqual(PermissionResolver.status(forAuthValue: 0), .denied)
        XCTAssertEqual(PermissionResolver.status(forAuthValue: 1), .unknown) // legacy one-shot
        XCTAssertEqual(PermissionResolver.status(forAuthValue: 3), .unknown) // limited (Photos)
    }

    // MARK: client matching

    func testMatchesBundleIDClient() {
        XCTAssertTrue(PermissionResolver.isClient("com.example.Foo", of: app))
    }

    func testMatchesExecutablePathClient() {
        XCTAssertTrue(PermissionResolver.isClient(
            "/Applications/Foo.app/Contents/MacOS/Foo", of: app))
    }

    func testRejectsForeignPath() {
        XCTAssertFalse(PermissionResolver.isClient(
            "/Applications/Bar.app/Contents/MacOS/Bar", of: app))
    }

    func testRejectsLookalikePathPrefix() {
        XCTAssertFalse(PermissionResolver.isClient(
            "/Applications/Foo.app.bak/Contents/MacOS/x", of: app))
    }

    func testRejectsOtherBundleID() {
        XCTAssertFalse(PermissionResolver.isClient("com.example.Bar", of: app))
    }

    // MARK: resolve

    func testResolveGrantedAndDenied() {
        let records = [
            record(service: "kTCCServiceCamera", client: "com.example.Foo", auth: 2),
            record(service: "kTCCServiceMicrophone", client: "com.example.Foo", auth: 0),
        ]
        let resolved = PermissionResolver.resolve(for: app, records: records, locationClients: [:])
        XCTAssertEqual(resolved.statuses[.camera], .authorized)
        XCTAssertEqual(resolved.statuses[.microphone], .denied)
        XCTAssertEqual(resolved.statuses[.location], .notRequested)
    }

    func testResolvePathBasedClient() {
        let records = [
            record(service: "kTCCServiceSystemPolicyAllFiles",
                   client: "/Applications/Foo.app/Contents/MacOS/Foo", auth: 2),
        ]
        let resolved = PermissionResolver.resolve(for: app, records: records, locationClients: [:])
        XCTAssertEqual(resolved.statuses[.fullDiskAccess], .authorized)
    }

    func testResolveAnyGrantedRowWins() {
        let records = [
            record(service: "kTCCServiceCamera", client: "com.example.Foo", auth: 0),
            record(service: "kTCCServiceCamera", client: "com.example.Foo", auth: 2),
        ]
        let resolved = PermissionResolver.resolve(for: app, records: records, locationClients: [:])
        XCTAssertEqual(resolved.statuses[.camera], .authorized)
    }

    func testResolveAllDeniedWins() {
        let records = [
            record(service: "kTCCServiceCamera", client: "com.example.Foo", auth: 0),
            record(service: "kTCCServiceCamera", client: "com.example.Foo", auth: 0),
        ]
        let resolved = PermissionResolver.resolve(for: app, records: records, locationClients: [:])
        XCTAssertEqual(resolved.statuses[.camera], .denied)
    }

    func testResolveLocationFallback() {
        let resolved = PermissionResolver.resolve(
            for: app, records: [], locationClients: ["com.example.Foo": .authorized])
        XCTAssertEqual(resolved.statuses[.location], .authorized)
    }

    func testResolveUntouchedServicesAreNotRequested() {
        let resolved = PermissionResolver.resolve(for: app, records: [], locationClients: [:])
        XCTAssertEqual(resolved.statuses.count, PermissionService.allCases.count)
        XCTAssertTrue(resolved.statuses.values.allSatisfy { $0 == .notRequested })
    }

    // MARK: risk level

    func testRiskCombos() {
        func entry(_ statuses: [PermissionService: PermissionStatus]) -> AppEntry {
            var permissions = ResolvedPermissions()
            permissions.statuses = statuses
            return AppEntry(app: app, permissions: permissions)
        }
        XCTAssertEqual(entry([.accessibility: .authorized, .screenRecording: .authorized]).riskLevel, .high)
        XCTAssertEqual(entry([.accessibility: .authorized]).riskLevel, .elevated)
        XCTAssertEqual(entry([.fullDiskAccess: .authorized]).riskLevel, .elevated)
        XCTAssertEqual(entry([.camera: .authorized]).riskLevel, .none)
        XCTAssertEqual(entry([:]).riskLevel, .none)
    }
}