// Copyright Ryan Francesconi. All Rights Reserved. Revision History at
// https://github.com/ryanfrancesconi/spfk-musical-analysis

import AVFoundation
import Foundation
import SPFKAudioBase
import SPFKBase

/// Detects the musical key of an audio file by scanning it in chunks and
/// voting on the most consistent result.
///
/// Each chunk is independently analyzed through the DSP pipeline
/// (`MusicalKeyDetector` → `KeyClassifier`) which returns both a key index
/// and a Pearson correlation indicating match strength. The per-chunk keys
/// are collected via ``CountableResult`` for consensus voting, and the
/// winning key's average correlation is checked against ``minimumConfidence``
/// before accepting the result.
///
/// Throws if no key reaches enough votes or if the winning key's average
/// correlation falls below the confidence threshold.
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

    /// Tracks the sum and count of correlations for each detected key value
    /// to compute an average confidence after scanning.
    private var correlationSums: [MusicalKeyValue: Float] = [:]
    private var correlationCounts: [MusicalKeyValue: Int] = [:]

    /// Minimum average Pearson correlation required for the winning key to be
    /// accepted. Below this threshold ``process()`` throws, indicating the
    /// audio has no reliable tonal content (e.g. noise, percussion).
    ///
    /// The default value of `0.5` works well for most recorded music. Set to
    /// `0` to disable confidence checking entirely.
    public private(set) var minimumConfidence: Float = 0.5

    /// Updates the minimum confidence threshold.
    ///
    /// - Parameter minimumConfidence: A value in `0...1`. Set to `0` to
    ///   accept any result regardless of correlation strength.
    public func update(minimumConfidence: Float) {
        self.minimumConfidence = minimumConfidence
    }

    var processTask: Task<Void, Error>?

    /// Maximum duration (in seconds) of each analysis chunk. Longer chunks
    /// produce more stable chroma averages but use more memory. Defaults to 60.
    public private(set) var maxAnalysisBufferDuration: TimeInterval = 60

    /// Updates the maximum analysis buffer duration.
    ///
    /// - Parameter maxAnalysisBufferDuration: Duration in seconds for each
    ///   analysis chunk.
    public func update(maxAnalysisBufferDuration: TimeInterval) {
        self.maxAnalysisBufferDuration = maxAnalysisBufferDuration
    }

    /// Creates a key analysis from a file URL.
    ///
    /// - Parameters:
    ///   - url: Path to the audio file.
    ///   - matchesRequired: Number of matching chunk votes needed for early
    ///     termination. Defaults to `2`.
    public init(url: URL, matchesRequired: Int? = nil) throws {
        let audioFile = try AVAudioFile(forReading: url)
        try self.init(audioFile: audioFile, matchesRequired: matchesRequired)
    }

    /// Creates a key analysis from an open `AVAudioFile`.
    ///
    /// - Parameters:
    ///   - audioFile: The audio file to analyze.
    ///   - matchesRequired: Number of matching chunk votes needed for early
    ///     termination. Defaults to `2`.
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
    /// Scans the audio file in chunks, classifies each chunk, collects votes,
    /// and returns the winning key if its average correlation meets
    /// ``minimumConfidence``.
    ///
    /// - Returns: The detected ``MusicalKeyValue``.
    /// - Throws: If no key can be determined, or if the winning key's
    ///   confidence is below ``minimumConfidence``.
    public func process() async throws -> MusicalKeyValue {
        processTask = Task<Void, Error> {
            let audioAnalysis = AudioFileScanner(
                bufferDuration: min(audioDuration / 6, maxAnalysisBufferDuration),
                sendPeriodicProgressEvery: 4,
                eventHandler: analyze(_:)
            )

            try await audioAnalysis.process(audioFile: audioFile)
        }

        // Bridge cancellation from the calling structured context into the
        // unstructured processTask. Without this, cancelling the parent task
        // (e.g. via a task group) won't reach AudioFileScanner's loop.
        let task = processTask
        _ = await withTaskCancellationHandler {
            await task?.result
        } onCancel: {
            task?.cancel()
        }

        guard let value = results.choose() else {
            throw NSError(description: "Failed to detect key")
        }

        // Check average correlation confidence for the winning key
        let avgCorrelation: Float
        if let sum = correlationSums[value], let count = correlationCounts[value], count > 0 {
            avgCorrelation = sum / Float(count)
        } else {
            avgCorrelation = 0
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
