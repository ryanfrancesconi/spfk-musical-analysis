// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-musical-analysis

import AVFoundation
import Foundation
import SPFKAudioBase
import SPFKBase

/// Detects the musical key of an audio file by scanning it in chunks and voting on the most
/// consistent result.
///
/// Each chunk goes through `MusicalKeyDetector` → `KeyClassifier` independently, and the winning
/// key's average Pearson correlation is checked against ``minimumConfidence`` before it is
/// accepted.
///
/// ## Example
///
/// ```swift
/// let analysis = try MusicalKeyAnalysis(url: audioURL, matchesRequired: 3)
/// let key = try await analysis.process() // e.g. "C Major"
/// ```
public actor MusicalKeyAnalysis {
    private let audioFile: AVAudioFile
    private var results: CountableResult<MusicalKeyValue>
    private let audioDuration: TimeInterval
    private let detector: MusicalKeyDetector

    /// Summed per key, divided by the count below for an average confidence after scanning.
    private var correlationSums: [MusicalKeyValue: Float] = [:]
    private var correlationCounts: [MusicalKeyValue: Int] = [:]

    /// Minimum average Pearson correlation for the winning key to be accepted; below it
    /// ``process()`` throws, meaning the audio has no reliable tonal content. `0.5` works well for
    /// most recorded music, and `0` disables the check entirely.
    public private(set) var minimumConfidence: Float = 0.5

    /// - Parameter minimumConfidence: A value in `0...1`.
    public func update(minimumConfidence: Float) {
        self.minimumConfidence = minimumConfidence
    }

    var processTask: Task<Void, Error>?

    /// Maximum duration in seconds of each analysis chunk. Longer chunks produce more stable
    /// chroma averages but use more memory.
    public private(set) var maxAnalysisBufferDuration: TimeInterval = 60

    public func update(maxAnalysisBufferDuration: TimeInterval) {
        self.maxAnalysisBufferDuration = maxAnalysisBufferDuration
    }

    /// - Parameter matchesRequired: Matching chunk votes needed for early termination, `2` by
    ///   default.
    public init(url: URL, matchesRequired: Int? = nil) throws {
        let audioFile = try AVAudioFile(forReading: url)
        try self.init(audioFile: audioFile, matchesRequired: matchesRequired)
    }

    /// - Parameter matchesRequired: Matching chunk votes needed for early termination, `2` by
    ///   default.
    public init(audioFile: AVAudioFile, matchesRequired: Int? = nil) throws {
        self.audioFile = audioFile
        audioDuration = audioFile.duration
        results = CountableResult(matchesRequired: matchesRequired ?? 2)

        guard let detector = MusicalKeyDetector() else {
            throw NSError(description: "Failed to initialize FFT processor")
        }

        self.detector = detector
    }

    /// Runs the key detection pipeline and returns the detected key.
    ///
    /// - Throws: If no key can be determined, or if the winning key's confidence is below
    ///   ``minimumConfidence``.
    public func process() async throws -> MusicalKeyValue {
        processTask = Task<Void, Error> {
            let audioAnalysis = AudioFileScanner(
                bufferDuration: min(audioDuration / 6, maxAnalysisBufferDuration),
                sendPeriodicProgressEvery: 4,
                eventHandler: analyze(_:)
            )

            try await audioAnalysis.process(audioFile: audioFile)
        }

        // Bridges cancellation from the calling structured context into the unstructured
        // processTask; without it, cancelling the parent never reaches AudioFileScanner's loop.
        let task = processTask
        _ = await withTaskCancellationHandler {
            await task?.result
        } onCancel: {
            task?.cancel()
        }

        // Read from the enclosing task, not `processTask` — that one is also cancelled by
        // `analyze(_:)` for early termination, which is not a user cancel.
        try Task.checkCancellation()

        guard let value = results.choose() else {
            throw NSError(description: "Failed to detect key")
        }

        let avgCorrelation: Float = if let sum = correlationSums[value], let count = correlationCounts[value], count > 0 {
            sum / Float(count)
        } else {
            0
        }

        guard avgCorrelation >= minimumConfidence else {
            throw NSError(description: "Key detection confidence too low (\(avgCorrelation))")
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
            let result = detector.detectKey(
                samples: samples.pointee,
                sampleCount: Int(length),
                sampleRate: Float(format.sampleRate)
            )

            if let value = MusicalKeyValue(keyIndex: Int32(result.keyIndex)) {
                correlationSums[value, default: 0] += result.correlation
                correlationCounts[value, default: 0] += 1

                if results.append(value) {
                    processTask?.cancel()
                }
            }

        case .complete:
            break
        }
    }
}
