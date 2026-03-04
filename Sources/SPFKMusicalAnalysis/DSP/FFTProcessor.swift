// Copyright Ryan Francesconi. All Rights Reserved. Revision History at
// https://github.com/ryanfrancesconi/spfk-musical-analysis

import Accelerate

/// Performs windowed FFT on audio frames and produces magnitude spectra.
///
/// Uses Apple's Accelerate vDSP framework for hardware-optimized FFT computation.
/// Applies a Hann window before the FFT, matching the C++ CKey pipeline.
final class FFTProcessor: @unchecked Sendable {
    let fftLength: Int
    let magnitudeLength: Int

    private let log2n: vDSP_Length
    private let fftSetup: FFTSetup
    private let window: [Float]

    /// Creates an FFT processor for the given block length.
    ///
    /// - Parameter blockLength: The number of samples per frame. Will be
    ///   rounded up to the next power of two internally.
    init?(blockLength: Int) {
        let log2n = vDSP_Length(ceil(log2(Double(blockLength))))
        self.log2n = log2n
        fftLength = 1 << Int(log2n)
        magnitudeLength = fftLength / 2 + 1

        guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            return nil
        }
        fftSetup = setup

        // Pre-compute Hann window
        var win = [Float](repeating: 0, count: fftLength)
        vDSP_hann_window(&win, vDSP_Length(fftLength), Int32(vDSP_HANN_NORM))
        window = win
    }

    /// Computes the magnitude spectrum of an audio frame.
    ///
    /// - Parameter frame: Time-domain audio samples. If shorter than `fftLength`,
    ///   the remainder is zero-padded.
    /// - Returns: Magnitude spectrum with `fftLength/2 + 1` values (DC through Nyquist).
    func magnitudeSpectrum(of frame: [Float]) -> [Float] {
        // Copy and zero-pad if necessary
        var windowed = [Float](repeating: 0, count: fftLength)
        let copyCount = min(frame.count, fftLength)

        for i in 0 ..< copyCount {
            windowed[i] = frame[i] * window[i]
        }

        // Set up split complex for vDSP FFT
        let halfN = fftLength / 2
        var realPart = [Float](repeating: 0, count: halfN)
        var imagPart = [Float](repeating: 0, count: halfN)

        // Pack interleaved real data into split complex form, then perform FFT
        realPart.withUnsafeMutableBufferPointer { realBuf in
            imagPart.withUnsafeMutableBufferPointer { imagBuf in
                guard let realBase = realBuf.baseAddress,
                      let imagBase = imagBuf.baseAddress
                else { return }

                var splitComplex = DSPSplitComplex(realp: realBase, imagp: imagBase)

                windowed.withUnsafeBytes { rawBuf in
                    guard let rawBase = rawBuf.baseAddress else { return }
                    let complexPtr = rawBase.assumingMemoryBound(to: DSPComplex.self)
                    vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(halfN))
                }

                // Perform real FFT
                vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
            }
        }

        // Scale by 1/(2*N) to match the C++ normalization
        var scale = 1.0 / Float(fftLength)
        vDSP_vsmul(realPart, 1, &scale, &realPart, 1, vDSP_Length(halfN))
        vDSP_vsmul(imagPart, 1, &scale, &imagPart, 1, vDSP_Length(halfN))

        // Compute magnitudes
        var magnitudes = [Float](repeating: 0, count: magnitudeLength)

        // DC component (packed in realPart[0], imagPart[0] contains Nyquist)
        magnitudes[0] = abs(realPart[0])
        magnitudes[halfN] = abs(imagPart[0])

        // Bins 1 through N/2-1
        for i in 1 ..< halfN {
            let re = realPart[i]
            let im = imagPart[i]
            magnitudes[i] = sqrt(re * re + im * im) * 2.0
        }

        return magnitudes
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }
}
