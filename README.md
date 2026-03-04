# SPFKMusicalAnalysis

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-musical-analysis%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanfrancesconi/spfk-musical-analysis)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-musical-analysis%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanfrancesconi/spfk-musical-analysis)

A pure Swift musical key detection library using a standard MIR (Music Information Retrieval) pipeline built on Apple's Accelerate framework.

## Overview

SPFKMusicalAnalysis detects the musical key of audio files by processing raw audio through a DSP pipeline: windowed FFT, pitch chroma extraction, and template matching against Temperley key profiles using Pearson correlation. It classifies audio into one of 24 keys (12 major + 12 minor).

Originally based on [Alexander Lerch's](https://github.com/alexanderlerch) C++ [libACA](https://github.com/ryanfrancesconi/CXXAudioContentAnalysis) key detection, the library has been rewritten entirely in Swift with improved accuracy (Temperley profiles + Pearson correlation vs. the original Krumhansl profiles + Manhattan distance).

## Platforms

- macOS 12+
- iOS 15+

## Architecture

```
Audio File
    │
    ▼
┌──────────────────────┐
│   MusicalKeyAnalysis  │  Public API — accepts AVAudioFile or URL
│   (actor)             │  Scans audio in chunks, collects key votes
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   MusicalKeyDetector  │  Orchestrator — frames audio into overlapping blocks
│   (struct)            │  Averages chroma across all frames, then classifies
└──────────┬───────────┘
           │
     ┌─────┴─────┐
     ▼           ▼
┌─────────┐ ┌────────────────┐
│   FFT    │ │ ChromaExtractor │  Hann-windowed FFT via vDSP
│Processor │ │   (struct)      │  12-bin pitch chroma filter bank
│ (class)  │ └───────┬────────┘
└─────────┘         │
                    ▼
           ┌───────────────┐
           │ KeyClassifier  │  Pearson correlation against
           │   (struct)     │  24 rotated Temperley key profiles
           └───────────────┘
                    │
                    ▼
           ┌───────────────┐
           │MusicalKeyValue │  Result: note name + tonality
           │   (struct)     │  e.g., "C Major", "F# Minor"
           └───────────────┘
```

## Features

### Key Detection Pipeline

The DSP pipeline processes audio through four stages:

1. **FFT Processing** (`FFTProcessor`) -- Applies a Hann window and computes magnitude spectra using `vDSP_fft_zrip`. Configurable block length (default 4096 samples) with automatic zero-padding to the next power of two.

2. **Chroma Extraction** (`ChromaExtractor`) -- Maps FFT magnitude bins to 12 pitch classes (C through B) using a filter bank spanning 4 octaves from C4. Each pitch class covers a quarter-tone-wide band, and the resulting chroma vector is L1-normalized.

3. **Key Classification** (`KeyClassifier`) -- Computes Pearson correlation between the averaged chroma vector and all 24 cyclically-rotated Temperley key profiles (12 major + 12 minor). Returns the key with the highest correlation, or "no key" if the best correlation falls below 0.2.

4. **Temporal Averaging** (`MusicalKeyDetector`) -- Blocks audio into overlapping frames (50% hop), extracts chroma from each frame, and averages across all frames before classification.

### Analysis

`MusicalKeyAnalysis` provides the high-level public API:

- Accepts `AVAudioFile` or file `URL`
- Scans audio in configurable chunk sizes (up to 60 seconds per chunk)
- Uses a voting system (`CountableResult`) that collects key detections from multiple chunks
- Supports early termination when enough matching votes are collected (`matchesRequired`)
- Fully concurrent -- implemented as a Swift `actor`

### Key Representation

`MusicalKeyValue` models a detected key as a note name + tonality pair:

- 12 note names (C through B, including sharps)
- Major and minor tonalities
- Relative key lookup (e.g., C Major ↔ A Minor)
- Initializable from key index (0--23), string ("C# Minor"), or components

## Usage

### Detect the Key of an Audio File

```swift
import SPFKMusicalAnalysis

let analysis = try MusicalKeyAnalysis(url: audioFileURL, matchesRequired: 3)
let key = try await analysis.process()

print(key) // e.g., "C Major"
print(key.name) // .c
print(key.tonality) // .major
print(key.relativeKey) // "A Minor"
```

### Configure Analysis Parameters

```swift
let audioFile = try AVAudioFile(forReading: url)
let analysis = try MusicalKeyAnalysis(audioFile: audioFile, matchesRequired: 5)

// Limit the maximum buffer size for each analysis chunk
await analysis.update(maxAnalysisBufferDuration: 30)

let key = try await analysis.process()
```

## Dependencies

- [spfk-base](https://github.com/ryanfrancesconi/spfk-base)
- [spfk-audio-base](https://github.com/ryanfrancesconi/spfk-audio-base)
- [spfk-testing](https://github.com/ryanfrancesconi/spfk-testing) (test target only)

## Installation

Add SPFKMusicalAnalysis to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ryanfrancesconi/spfk-musical-analysis", from: "0.0.1"),
]
```

Then add it as a dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SPFKMusicalAnalysis", package: "spfk-musical-analysis"),
    ]
)
```

## License

Copyright Ryan Francesconi. All Rights Reserved.

