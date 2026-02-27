import AVFoundation
import SPFKAudioBase
import SPFKAudioContentAnalysis
import SPFKAudioContentAnalysisC
import SPFKBase
import SPFKTesting
import Testing

struct MusicalKeyTests: TestCaseModel {
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

    @Test func musicalKeyAnalysis() async throws {
        let url = URL(fileURLWithPath: "/Users/rf/Downloads/TestResources/guitar-12-08-24.wav")
        let mka = try MusicalKeyAnalysis(url: url, matchesRequired: 3)
        let key = try await mka.process()

        #expect(key == .init(name: .fSharp, modality: .minor))
    }

    @Test func mostLikely() async throws {
        let list: CountableResult<MusicalKeyValue> = [
            .init(name: .a, modality: .major),
            .init(name: .a, modality: .major),
            .init(name: .a, modality: .minor),
            .init(name: .b, modality: .major),
        ]

        let result: MusicalKeyValue = list.mostLikely()!

        #expect(result == .init(name: .a, modality: .major))
    }
}
