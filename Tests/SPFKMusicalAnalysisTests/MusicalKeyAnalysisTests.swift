import AVFoundation
import SPFKAudioBase
import SPFKMusicalAnalysis
import SPFKBase
import SPFKTesting
import Testing

struct MusicalKeyAnalysisTests: TestCaseModel {
    /// Returns the bundled MP3 URL for a given major key note.
    static func majorKeyURL(for note: NoteName) -> URL {
        let resources = TestBundleResources.shared
        return switch note {
        case .c: resources.key_c_major
        case .cSharp: resources.key_csharp_major
        case .d: resources.key_d_major
        case .dSharp: resources.key_dsharp_major
        case .e: resources.key_e_major
        case .f: resources.key_f_major
        case .fSharp: resources.key_fsharp_major
        case .g: resources.key_g_major
        case .gSharp: resources.key_gsharp_major
        case .a: resources.key_a_major
        case .aSharp: resources.key_asharp_major
        case .b: resources.key_b_major
        }
    }

    // MARK: - Key detection tests

    @Test(.tags(.file))
    func musicalKeyAnalysis_cMajor() async throws {
        let url = TestBundleResources.shared.key_c_major
        let mka = try MusicalKeyAnalysis(url: url, matchesRequired: 10)
        let key = try await mka.process()
        #expect(key == .init(name: .c, tonality: .major))
    }

    @Test(.tags(.file), arguments: NoteName.allCases)
    func majorKeyAnalysis(note: NoteName) async throws {
        let url = Self.majorKeyURL(for: note)
        let value = MusicalKeyValue(name: note, tonality: .major)

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
        // A short percussive cowbell sample has no clear tonal content,
        // so it should be rejected by the confidence threshold.
        await #expect(throws: (any Error).self) {
            _ = try await mka.process()
        }
    }
}
