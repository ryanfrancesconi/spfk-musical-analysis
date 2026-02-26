import AVFoundation
import SPFKAudioBase
import SPFKAudioContentAnalysis
import SPFKAudioContentAnalysisC
import SPFKBase
import SPFKTesting
import Testing

struct ACATests: TestCaseModel {
    @Test func parse() async throws {
        let buffer = try AVAudioPCMBuffer(
            url: URL(fileURLWithPath: "/Users/rf/Downloads/TestResources/guitar-12-08-24.wav"))!
        let rawData = try #require(buffer.floatChannelData)

        let key = MusicalKey(
            data: rawData.pointee,
            numberOfSamples: Int32(buffer.frameLength),
            sampleRate: Float(buffer.format.sampleRate)
        )

        Log.debug(key.index, key.stringValue)
        Log.debug(MusicalKeyValue(rawValue: key.index))
    }
}
