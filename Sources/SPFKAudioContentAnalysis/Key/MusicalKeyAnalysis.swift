// Copyright Ryan Francesconi. All Rights Reserved. Revision History at
// https://github.com/ryanfrancesconi/spfk-audio-content-analysis

import AVFoundation
import Foundation
import SPFKAudioBase
import SPFKAudioContentAnalysisC
import SPFKBase

public actor MusicalKeyAnalysis {
    private let audioFile: AVAudioFile
    private var results: CountableResult<MusicalKeyValue>

    var processTask: Task<Void, Error>?

    public init(url: URL, matchesRequired: Int? = nil) throws {
        let audioFile = try AVAudioFile(forReading: url)
        self.init(audioFile: audioFile, matchesRequired: matchesRequired)
    }

    public init(audioFile: AVAudioFile, matchesRequired: Int? = nil) {
        self.audioFile = audioFile
        results = CountableResult(matchesRequired: 2)
    }

    public func process() async throws -> MusicalKeyValue {
        processTask = Task<Void, Error> {
            let audioAnalysis = AudioFileScanner(
                bufferDuration: audioFile.duration / 6,
                sendPeriodicProgressEvery: 4,
                eventHandler: analyze(_:)
            )

            try await audioAnalysis.process(audioFile: audioFile)
        }

        _ = await processTask?.result

        guard let value = results.choose() else {
            throw NSError(description: "Failed to detect key")
        }

        return value
    }

    private func analyze(_ event: AudioFileScannerEvent) async {
        switch event {
        case .progress:
            break

        case .periodicProgress:
            break

        case let .data(format: format, length: length, samples: samples):
            let key = MusicalKey(
                data: samples.pointee,
                numberOfSamples: Int32(length),
                sampleRate: Float(format.sampleRate)
            )

            if let value = MusicalKeyValue(cObject: key) {
                // Log.debug(value.description)

                if results.append(value) {
                    // Log.debug(value, "matchesRequired", results.matchesRequired)
                    processTask?.cancel()
                }
            }

        case .complete:
            break
        }
    }
}
