// Copyright Ryan Francesconi. All Rights Reserved. Revision History at
// https://github.com/ryanfrancesconi/spfk-musical-analysis

import AVFoundation
import Foundation
import SPFKAudioBase
import SPFKMusicalAnalysisC
import SPFKBase

public actor MusicalKeyAnalysis {
    private let audioFile: AVAudioFile
    private var results: CountableResult<MusicalKeyValue>
    private let audioDuration: TimeInterval

    var processTask: Task<Void, Error>?

    public private(set) var maxAnalysisBufferDuration: TimeInterval = 60
    public func update(maxAnalysisBufferDuration: TimeInterval) {
        self.maxAnalysisBufferDuration = maxAnalysisBufferDuration
    }

    public init(url: URL, matchesRequired: Int? = nil) throws {
        let audioFile = try AVAudioFile(forReading: url)
        self.init(audioFile: audioFile, matchesRequired: matchesRequired)
    }

    public init(audioFile: AVAudioFile, matchesRequired: Int? = nil) {
        self.audioFile = audioFile
        audioDuration = audioFile.duration
        results = CountableResult(matchesRequired: matchesRequired ?? 2)
    }

    public func process() async throws -> MusicalKeyValue {
        processTask = Task<Void, Error> {
            let audioAnalysis = AudioFileScanner(
                bufferDuration: min(audioDuration / 6, maxAnalysisBufferDuration),
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
                if results.append(value) {
                    processTask?.cancel()
                }
            }

        case .complete:
            break
        }
    }
}
