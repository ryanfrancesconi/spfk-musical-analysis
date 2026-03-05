import Foundation
import SPFKAudioBase
import SPFKBase
import SPFKTesting
import Testing

@testable import SPFKMusicalAnalysis

@Suite("Key Detection Confidence")
struct KeyDetectionConfidenceTests {
    // MARK: - KeyClassifier unit tests

    @Test("Flat chroma produces low correlation")
    func flatChromaLowCorrelation() {
        let flat: [Float] = Array(repeating: 1.0, count: 12)
        let result = KeyClassifier().classify(flat)
        // A perfectly flat chroma has zero variance, so Pearson correlation is 0
        #expect(result.keyIndex == 24)
        #expect(result.correlation < 0.2)
    }

    @Test("Strong tonal chroma produces high correlation")
    func tonalChromaHighCorrelation() {
        // C major profile itself should produce a perfect correlation
        let result = KeyClassifier().classify(KeyClassifier.majorProfile)
        #expect(result.keyIndex == 0) // C Major
        #expect(result.correlation > 0.9)
    }

    @Test("Correlation is in expected range", arguments: 0 ..< 24)
    func correlationRange(keyIndex: Int) {
        // Build a chroma from the key profile for this key index
        let shift = keyIndex % 12
        let profile = keyIndex < 12 ? KeyClassifier.majorProfile : KeyClassifier.minorProfile
        var chroma = [Float](repeating: 0, count: 12)
        for i in 0 ..< 12 {
            chroma[i] = profile[(i - shift + 12) % 12]
        }
        let result = KeyClassifier().classify(chroma)
        #expect(result.correlation >= -1.0 && result.correlation <= 1.0)
    }

    // MARK: - Integration tests with audio files

    @Test(.tags(.file))
    func pinkNoiseThrowsLowConfidence() async throws {
        let url = TestBundleResources.shared.pink_noise
        guard url.exists else { return }

        let mka = try MusicalKeyAnalysis(url: url, matchesRequired: 10)

        await #expect(throws: (any Error).self) {
            _ = try await mka.process()
        }
    }

    @Test(.tags(.file))
    func tonalAudioExceedsConfidenceThreshold() async throws {
        let url = TestBundleResources.shared.key_c_major
        let mka = try MusicalKeyAnalysis(url: url, matchesRequired: 3)
        // Should not throw — tonal content exceeds the default 0.5 threshold
        let key = try await mka.process()
        #expect(key.tonality == .major || key.tonality == .minor)
    }

    @Test(.tags(.file))
    func customConfidenceThresholdRejectsWeakMatch() async throws {
        let url = TestBundleResources.shared.key_c_major
        let mka = try MusicalKeyAnalysis(url: url, matchesRequired: 3)
        // Set an unreasonably high threshold that no real audio can meet
        await mka.update(minimumConfidence: 0.99)

        await #expect(throws: (any Error).self) {
            _ = try await mka.process()
        }
    }

    @Test(.tags(.file))
    func zeroConfidenceThresholdAlwaysAccepts() async throws {
        let url = TestBundleResources.shared.cowbell_wav
        let mka = try MusicalKeyAnalysis(url: url, matchesRequired: 1)
        // Disable confidence checking — even a cowbell should return a key
        await mka.update(minimumConfidence: 0)
        let key = try await mka.process()
        #expect(key.tonality == .major || key.tonality == .minor)
    }
}
