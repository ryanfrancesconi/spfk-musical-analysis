// Copyright Ryan Francesconi. All Rights Reserved. Revision History at
// https://github.com/ryanfrancesconi/spfk-musical-analysis

import Accelerate

/// Pure Swift musical key detector that replaces the C++ CKey implementation.
///
/// Processes raw audio samples through a standard MIR pipeline:
/// 1. Block audio into overlapping frames (Hann-windowed)
/// 2. FFT each frame to produce magnitude spectra
/// 3. Extract 12-bin pitch chroma from each spectrum
/// 4. Average chroma across all frames
/// 5. Classify averaged chroma against Temperley key profiles
///
/// Returns both a key index and a Pearson correlation value indicating
/// how strongly the chroma matches the best key profile.
struct MusicalKeyDetector: Sendable {
    /// Number of samples per analysis frame (default 4096).
    let blockLength: Int

    /// Number of samples to advance between frames (default 2048 = 50% overlap).
    let hopLength: Int

    private let fft: FFTProcessor

    /// Creates a key detector with the specified frame parameters.
    ///
    /// - Parameters:
    ///   - blockLength: Samples per frame (default 4096).
    ///   - hopLength: Hop size between frames (default 2048).
    init?(blockLength: Int = 4096, hopLength: Int = 2048) {
        self.blockLength = blockLength
        self.hopLength = hopLength
        guard let processor = FFTProcessor(blockLength: blockLength) else {
            return nil
        }
        fft = processor
    }

    /// Result of key detection containing key index and confidence.
    struct Result: Sendable {
        /// Key index (0–11 major, 12–23 minor, 24 no key), or -1 if insufficient data.
        let keyIndex: Int
        /// Pearson correlation strength of the best key match (higher = more confident).
        let correlation: Float
    }

    /// Detects the musical key from raw audio samples.
    ///
    /// - Parameters:
    ///   - samples: Mono audio samples as a float pointer.
    ///   - sampleCount: Number of samples.
    ///   - sampleRate: The audio sample rate in Hz.
    /// - Returns: A ``Result`` containing the key index and correlation strength.
    func detectKey(samples: UnsafePointer<Float>, sampleCount: Int, sampleRate: Float) -> Result {
        guard sampleCount >= blockLength else { return Result(keyIndex: -1, correlation: 0) }

        let chromaExtractor = ChromaExtractor(
            fftLength: fft.fftLength,
            sampleRate: sampleRate
        )

        let numBlocks = (sampleCount - blockLength) / hopLength + 1
        guard numBlocks > 0 else { return Result(keyIndex: -1, correlation: 0) }

        // Accumulate chroma vectors across all frames
        var chromaSum = [Float](repeating: 0, count: 12)

        for block in 0 ..< numBlocks {
            let offset = block * hopLength

            // Extract frame from sample buffer
            let frame = Array(UnsafeBufferPointer(start: samples + offset, count: blockLength))

            // FFT → magnitude spectrum → chroma
            let magnitude = fft.magnitudeSpectrum(of: frame)
            let chroma = chromaExtractor.chroma(from: magnitude)

            // Accumulate
            vDSP_vadd(chromaSum, 1, chroma, 1, &chromaSum, 1, 12)
        }

        // Compute mean chroma
        var divisor = Float(numBlocks)
        vDSP_vsdiv(chromaSum, 1, &divisor, &chromaSum, 1, 12)

        // Classify
        let classifier = KeyClassifier()
        let result = classifier.classify(chromaSum)
        return Result(keyIndex: result.keyIndex, correlation: result.correlation)
    }
}
