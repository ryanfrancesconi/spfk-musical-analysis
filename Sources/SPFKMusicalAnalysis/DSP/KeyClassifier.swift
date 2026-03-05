// Copyright Ryan Francesconi. All Rights Reserved. Revision History at
// https://github.com/ryanfrancesconi/spfk-musical-analysis

import Accelerate

/// Classifies a 12-element pitch chroma vector into one of 24 musical keys
/// (12 major + 12 minor) using key profile template matching with Pearson
/// correlation.
///
/// Uses Temperley key profiles, which perform well on recorded music.
/// The classification computes Pearson correlation between the input chroma
/// and all 24 cyclically-rotated key profile templates, returning the key
/// index with the highest correlation.
///
/// Key index mapping:
/// - 0–11: C Major through B Major
/// - 12–23: C Minor through B Minor
/// - 24: No key detected
struct KeyClassifier: Sendable {
    /// Temperley major key profile (MIREX-optimized).
    static let majorProfile: [Float] = [
        5.0, 2.0, 3.5, 2.0, 4.5, 4.0,
        2.0, 4.5, 2.0, 3.5, 1.5, 4.0
    ]

    /// Temperley minor key profile (MIREX-optimized).
    static let minorProfile: [Float] = [
        5.0, 2.0, 3.5, 4.5, 2.0, 4.0,
        2.0, 4.5, 3.5, 2.0, 1.5, 4.0
    ]

    init() {}

    /// Result of a key classification, containing both the key index and the
    /// Pearson correlation strength of the best match.
    struct Result: Sendable {
        /// Key index: 0–11 = C Major..B Major, 12–23 = C Minor..B Minor, 24 = no key.
        let keyIndex: Int
        /// Pearson correlation of the best-matching key profile (range roughly -1...1).
        let correlation: Float
    }

    /// Classifies a 12-element chroma vector into a key index with correlation.
    ///
    /// - Parameter chroma: A 12-element array of pitch class energies
    ///   (C, C#, D, ..., B). Does not need to be pre-normalized.
    /// - Returns: A ``Result`` containing the best key index (0–11 major,
    ///   12–23 minor, or 24 for no key) and the Pearson correlation strength
    ///   of the match. Correlations below 0.2 are mapped to key index 24.
    func classify(_ chroma: [Float]) -> Result {
        precondition(chroma.count == 12)

        var bestIndex = 24
        var bestCorrelation: Float = -.greatestFiniteMagnitude

        // Test all 24 keys (12 major + 12 minor) by rotating profiles
        for shift in 0 ..< 12 {
            // Rotate profiles so index 0 aligns with pitch class `shift`
            var shiftedMajor = [Float](repeating: 0, count: 12)
            var shiftedMinor = [Float](repeating: 0, count: 12)

            for i in 0 ..< 12 {
                shiftedMajor[i] = Self.majorProfile[(i - shift + 12) % 12]
                shiftedMinor[i] = Self.minorProfile[(i - shift + 12) % 12]
            }

            let corrMajor = Self.pearsonCorrelation(chroma, shiftedMajor)
            if corrMajor > bestCorrelation {
                bestCorrelation = corrMajor
                bestIndex = shift
            }

            let corrMinor = Self.pearsonCorrelation(chroma, shiftedMinor)
            if corrMinor > bestCorrelation {
                bestCorrelation = corrMinor
                bestIndex = shift + 12
            }
        }

        // "No key" check — if best correlation is very low, the chroma
        // is likely noise or has no tonal content
        if bestCorrelation < 0.2 {
            return Result(keyIndex: 24, correlation: bestCorrelation)
        }

        return Result(keyIndex: bestIndex, correlation: bestCorrelation)
    }

    /// Computes Pearson correlation coefficient between two equal-length arrays.
    static func pearsonCorrelation(_ a: [Float], _ b: [Float]) -> Float {
        precondition(a.count == b.count)
        let n = Float(a.count)

        var sumA: Float = 0
        var sumB: Float = 0
        vDSP_sve(a, 1, &sumA, vDSP_Length(a.count))
        vDSP_sve(b, 1, &sumB, vDSP_Length(b.count))
        let meanA = sumA / n
        let meanB = sumB / n

        var numerator: Float = 0
        var denomA: Float = 0
        var denomB: Float = 0

        for i in 0 ..< a.count {
            let da = a[i] - meanA
            let db = b[i] - meanB
            numerator += da * db
            denomA += da * da
            denomB += db * db
        }

        let denominator = sqrt(denomA * denomB)
        guard denominator > 0 else { return 0 }
        return numerator / denominator
    }

    /// L1-normalizes an array so its elements sum to 1.0.
    static func l1Normalize(_ values: [Float]) -> [Float] {
        var sum: Float = 0
        vDSP_sve(values, 1, &sum, vDSP_Length(values.count))

        guard sum > 0 else { return values }

        var result = [Float](repeating: 0, count: values.count)
        var divisor = sum
        vDSP_vsdiv(values, 1, &divisor, &result, 1, vDSP_Length(values.count))
        return result
    }
}
