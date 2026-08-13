// Copyright Ryan Francesconi. All Rights Reserved.

import Foundation
import SPFKBase
import SPFKTesting
import Testing

@testable import SPFKMusicalAnalysis

@Suite(.tags(.file))
struct MusicalKeyAnalysisCancellationTests {
    /// Both the "no key" and the "confidence too low" exits sit after the scan, so a cancel
    /// reaching either is recorded by `PlaylistProcessor` as a failed file rather than a cancel.
    @Test("a cancelled task throws CancellationError, not a detection failure")
    func cancellationIsNotADetectionFailure() async throws {
        let url = TestBundleResources.shared.tabla_wav

        let task = Task {
            try await MusicalKeyAnalysis(url: url).process()
        }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
}
