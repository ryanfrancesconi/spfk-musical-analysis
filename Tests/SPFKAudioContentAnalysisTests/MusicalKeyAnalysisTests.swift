import AVFoundation
import SPFKAudioBase
import SPFKAudioContentAnalysis
import SPFKAudioContentAnalysisC
import SPFKBase
import SPFKTesting
import Testing

struct MusicalKeyAnalysisTests: TestCaseModel {
    @Test func musicalKeyC() async throws {
        let buffer = try AVAudioPCMBuffer(
            url: URL(fileURLWithPath: "/Users/rf/Downloads/TestResources/guitar-12-08-24.wav"))!
        let rawData = try #require(buffer.floatChannelData)

        let key = MusicalKey(
            data: rawData.pointee,
            numberOfSamples: Int32(buffer.frameLength),
            sampleRate: Float(buffer.format.sampleRate)
        )

        let value = MusicalKeyValue(cObject: key)

        Log.debug(value)
    }

    @Test func musicalKeyAnalysis_cMajor() async throws {
        let url = URL(fileURLWithPath: "/Users/rf/Documents/Dev/Spongefork/TestResources/C Major.mp3")
        let mka = try MusicalKeyAnalysis(url: url, matchesRequired: 3)
        let key = try await mka.process()
        #expect(key == .init(name: .c, tonality: .major))
    }

    @Test func majorKeyAnalysis() async throws {
        for note in NoteName.allCases {
            let value = MusicalKeyValue(name: note, tonality: .major)
            let url = URL(fileURLWithPath: "/Users/rf/Documents/Dev/Spongefork/TestResources/\(value.description).mp3")

            guard url.exists else {
                Issue.record("\(url.path) is missing")
                continue
            }

            let mka = try MusicalKeyAnalysis(url: url, matchesRequired: 3)
            let key = try await mka.process()

            #expect(key == value)
        }
    }

    @Test func mostLikely() async throws {
        let list: CountableResult<MusicalKeyValue> = [
            .init(name: .a, tonality: .major),
            .init(name: .a, tonality: .major),
            .init(name: .a, tonality: .minor),
            .init(name: .b, tonality: .major),
        ]

        let result: MusicalKeyValue = list.mostLikely()!

        #expect(result == .init(name: .a, tonality: .major))
    }
}
