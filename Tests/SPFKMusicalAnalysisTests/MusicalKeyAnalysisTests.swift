import AVFoundation
import SPFKAudioBase
import SPFKMusicalAnalysis
import SPFKMusicalAnalysisC
import SPFKBase
import SPFKTesting
import Testing

struct MusicalKeyAnalysisTests: TestCaseModel {
    // MARK: - Local integration tests (require files on disk)

    @Test(.tags(.development))
    func musicalKeyC() async throws {
        let buffer = try AVAudioPCMBuffer(
            url: URL(fileURLWithPath: "/Users/rf/Downloads/TestResources/guitar-12-08-24.wav"))!
        let rawData = try #require(buffer.floatChannelData)

        let key = MusicalKey(
            data: rawData.pointee,
            numberOfSamples: Int32(buffer.frameLength),
            sampleRate: Float(buffer.format.sampleRate)
        )

        let value = try #require(MusicalKeyValue(cObject: key))
        #expect(value.tonality == .major || value.tonality == .minor)
    }

    @Test(.tags(.development))
    func musicalKeyAnalysis_cMajor() async throws {
        let url = URL(fileURLWithPath: "/Users/rf/Documents/Dev/Spongefork/TestResources/C Major.mp3")
        let mka = try MusicalKeyAnalysis(url: url, matchesRequired: 10)
        let key = try await mka.process()
        #expect(key == .init(name: .c, tonality: .major))
    }

    @Test(.tags(.development), arguments: NoteName.allCases)
    func majorKeyAnalysis(note: NoteName) async throws {
        let value = MusicalKeyValue(name: note, tonality: .major)
        let url = URL(fileURLWithPath: "/Users/rf/Documents/Dev/Spongefork/TestResources/\(value.description).mp3")

        guard url.exists else {
            Issue.record("\(url.path) is missing")
            return
        }

        let mka = try MusicalKeyAnalysis(url: url, matchesRequired: 3)
        let key = try await mka.process()

        #expect(key == value || key == value.relativeKey)
    }

    // MARK: - Portable tests

    @Test func choose() async throws {
        let list: CountableResult<MusicalKeyValue> = [
            .init(name: .a, tonality: .major),
            .init(name: .a, tonality: .major),
            .init(name: .a, tonality: .minor),
            .init(name: .a, tonality: .minor),
            .init(name: .b, tonality: .major),
        ]

        let resultA: MusicalKeyValue = list.choose(tieBreakerWeight: .first)!
        let resultB: MusicalKeyValue = list.choose(tieBreakerWeight: .last)!

        #expect(resultA == .init(name: .a, tonality: .major))
        #expect(resultB == .init(name: .a, tonality: .minor))
    }

    @Test func invalidURLThrows() async throws {
        #expect(throws: (any Error).self) {
            try MusicalKeyAnalysis(url: URL(fileURLWithPath: "/nonexistent/file.wav"))
        }
    }

    @Test(.tags(.file))
    func musicalKeyAnalysisWithTestBundle() async throws {
        let url = TestBundleResources.shared.cowbell_wav
        let mka = try MusicalKeyAnalysis(url: url, matchesRequired: 1)
        let key = try await mka.process()
        // Just verify it returns a valid key (not testing accuracy on a short cowbell sample)
        #expect(key.tonality == .major || key.tonality == .minor)
    }
}
