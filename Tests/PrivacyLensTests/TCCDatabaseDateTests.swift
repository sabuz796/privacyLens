import XCTest
@testable import PrivacyLens

/// The epoch auto-detection heuristic: values ≥ 1e9 are Unix epoch,
/// smaller ones Apple epoch (2001-01-01).
final class TCCDatabaseDateTests: XCTestCase {
    func testZeroAndNegativeReturnNil() {
        XCTAssertNil(TCCDatabase.date(fromLastModified: 0))
        XCTAssertNil(TCCDatabase.date(fromLastModified: -5))
    }

    func testUnixEpoch() {
        let date = TCCDatabase.date(fromLastModified: 1_700_000_000)
        XCTAssertEqual(date?.timeIntervalSince1970 ?? 0, 1_700_000_000, accuracy: 1)
    }

    func testAppleEpoch() {
        // Apple-epoch seconds since 2001-01-01 (well below 1e9).
        let seconds: Int64 = 500_000_000
        let date = TCCDatabase.date(fromLastModified: seconds)
        XCTAssertEqual(date?.timeIntervalSinceReferenceDate ?? 0, TimeInterval(seconds), accuracy: 1)
    }

    func testFutureDateRejected() {
        XCTAssertNil(TCCDatabase.date(fromLastModified: 4_000_000_000)) // year 2096
    }

    func testPre2001Rejected() {
        XCTAssertNil(TCCDatabase.date(fromLastModified: 0))
    }
}