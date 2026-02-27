// Copyright Ryan Francesconi. All Rights Reserved. Revision History at
// https://github.com/ryanfrancesconi/spfk-audio-content-analysis

import Foundation
import SPFKAudioBase
import SPFKAudioContentAnalysisC

public struct MusicalKeyValue: Sendable, Hashable, Equatable, CustomStringConvertible {
    public var name: NoteName
    public var tonality: MusicalTonality

    public var description: String {
        "\(name) \(tonality)"
    }

    /**
     `keyIndex` is the numeric value in CXXAudioContentAnalysis `CKey::Keys_t`

     0: C Major
     1: C# Major/Db Major
     2: D Major
     3: D# Major/Eb Major
     4: E Major
     5: F Major
     6: F# Major/Gb Major
     7: G Major
     8: G# Major/Ab Major
     9: A Major
     10: A# Major/Bb Major
     11: B Major
     ---
     12: C Minor
     13: C# Minor/Db Minor
     14: D Minor
     15: D# Minor/Eb Minor
     16: E Minor
     17: F Minor
     18: F# Minor/Gb Minor
     19: G Minor
     20: G# Minor/Ab Minor
     21: A Minor
     22: A# Minor/Bb Minor
     23: B Minor
     ---
     24: No Chord

     MusicalKeyValue is reorganizing this information into a node name and a tonality.
      */
    public init?(keyIndex: Int32) {
        guard keyIndex >= 0, keyIndex <= 23 else {
            return nil
        }

        tonality = (12 ... 23).contains(keyIndex) ? .minor : .major

        let nameValue: Int32 = keyIndex >= 12 ? keyIndex - 12 : keyIndex

        guard let keyName = NoteName(rawValue: nameValue) else { return nil }

        name = keyName
    }

    public init(name: NoteName, tonality: MusicalTonality) {
        self.name = name
        self.tonality = tonality
    }

    public init?(cObject: MusicalKey) {
        guard let value = MusicalKeyValue(keyIndex: cObject.keyIndex) else { return nil }
        self = value
    }

    public init?(string: String) {
        let parts = string.components(separatedBy: " ").map(\.trimmed)

        guard parts.count == 2 else { return nil }

        guard let name = NoteName(string: parts[0]) else { return nil }
        guard let tonality = MusicalTonality(string: parts[1]) else { return nil }

        self = .init(name: name, tonality: tonality)
    }
}
