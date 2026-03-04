// Copyright Ryan Francesconi. All Rights Reserved. Revision History at
// https://github.com/ryanfrancesconi/spfk-musical-analysis

import Accelerate

/// Extracts a 12-element pitch chroma vector from a magnitude spectrum.
///
/// Builds a filter bank that maps FFT magnitude bins to 12 pitch classes
/// (C, C#, D, ..., B), aggregating energy across multiple octaves starting
/// from C4 (MIDI 60, 261.63 Hz). Each pitch class filter covers a
/// quarter-tone-wide band centered on the pitch frequency.
struct ChromaExtractor: Sendable {
    /// The 12 × magnitudeLength filter bank matrix (flattened row-major).
    private let filterBank: [Float]
    private let magnitudeLength: Int

    /// Creates a chroma extractor for the given FFT and sample rate parameters.
    ///
    /// - Parameters:
    ///   - fftLength: The FFT size (must be power of two).
    ///   - sampleRate: The audio sample rate in Hz.
    ///   - numOctaves: Number of octaves to aggregate (default 4).
    init(fftLength: Int, sampleRate: Float, numOctaves: Int = 4) {
        let magLen = fftLength / 2 + 1
        magnitudeLength = magLen

        // Quarter-tone ratio: 2^(1/24) — defines half-semitone-wide bands
        let quarterToneRatio: Float = pow(2.0, 1.0 / 24.0)

        // Build 12 × magLen filter bank
        var bank = [Float](repeating: 0, count: 12 * magLen)

        // Starting pitch: C4 = MIDI 60
        var fMid = 440.0 * pow(2.0, Float(60 - 69) / 12.0) // 261.63 Hz

        // Reduce octave count if highest pitch would exceed Nyquist
        let nyquist = sampleRate / 2.0
        var actualOctaves = numOctaves
        while actualOctaves > 1 {
            let highestFreq = fMid * pow(2.0, Float(actualOctaves - 1)) * quarterToneRatio
            if highestFreq < nyquist { break }
            actualOctaves -= 1
        }

        for pitchClass in 0 ..< 12 {
            var octaveMid = fMid

            for _ in 0 ..< actualOctaves {
                let fLow = octaveMid / quarterToneRatio
                let fHigh = octaveMid * quarterToneRatio

                // Convert frequencies to FFT bin indices
                let binLow = max(0, Int(round(fLow * Float(fftLength) / sampleRate)))
                let binHigh = min(magLen - 1, Int(round(fHigh * Float(fftLength) / sampleRate)))

                let binCount = binHigh - binLow + 1
                if binCount > 0 {
                    let weight = 1.0 / Float(binCount)
                    let rowOffset = pitchClass * magLen
                    for bin in binLow ... binHigh {
                        bank[rowOffset + bin] = weight
                    }
                }

                // Advance to next octave
                octaveMid *= 2.0
            }

            // Advance to next pitch class (semitone = 2 quarter tones)
            fMid *= quarterToneRatio * quarterToneRatio
        }

        filterBank = bank
    }

    /// Extracts a 12-element chroma vector from a magnitude spectrum.
    ///
    /// - Parameter magnitudeSpectrum: The magnitude spectrum from `FFTProcessor`.
    /// - Returns: A 12-element L1-normalized pitch chroma vector.
    func chroma(from magnitudeSpectrum: [Float]) -> [Float] {
        precondition(magnitudeSpectrum.count == magnitudeLength)

        // Square the magnitudes (power spectrum)
        var powerSpectrum = [Float](repeating: 0, count: magnitudeLength)
        vDSP_vsq(magnitudeSpectrum, 1, &powerSpectrum, 1, vDSP_Length(magnitudeLength))

        // Compute chroma: for each pitch class, dot product with filter bank row
        var chroma = [Float](repeating: 0, count: 12)

        for pitchClass in 0 ..< 12 {
            let rowOffset = pitchClass * magnitudeLength
            filterBank.withUnsafeBufferPointer { bankPtr in
                let rowStart = bankPtr.baseAddress! + rowOffset
                powerSpectrum.withUnsafeBufferPointer { specPtr in
                    vDSP_dotpr(rowStart, 1, specPtr.baseAddress!, 1,
                               &chroma[pitchClass], vDSP_Length(magnitudeLength))
                }
            }
        }

        // L1-normalize
        return KeyClassifier.l1Normalize(chroma)
    }
}
