// Copyright Ryan Francesconi. All Rights Reserved. Revision History at
// https://github.com/ryanfrancesconi/spfk-musical-analysis

import Foundation
import SPFKAudioBase

public struct MusicalKeyValue: Sendable, Hashable, Equatable, CustomStringConvertible {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name && lhs.tonality == rhs.tonality
    }

    public var name: NoteName
    public var tonality: MusicalTonality

    public var description: String {
        "\(name) \(tonality)"
    }

    public var keyIndex: Int32 {
        var value = name.rawValue

        if tonality == .minor {
            value += 12
        }

        return value
    }

    /**
     `keyIndex` is the numeric key index used by the key detection pipeline.

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

     MusicalKeyValue is reorganizing this information into a note name and a tonality.
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

    public init?(string: String) {
        let parts = string.components(separatedBy: " ").map(\.trimmed)

        guard parts.count == 2 else { return nil }

        guard let name = NoteName(string: parts[0]) else { return nil }
        guard let tonality = MusicalTonality(string: parts[1]) else { return nil }

        self = .init(name: name, tonality: tonality)
    }
}

// swiftformat:disable consecutiveSpaces

extension MusicalKeyValue {
    public var relativeKey: MusicalKeyValue {
        switch (name, tonality) {
        // --- Major to Minor
        case (.c, .major):      .init(name: .a, tonality: .minor)
        case (.cSharp, .major): .init(name: .aSharp, tonality: .minor)
        case (.d, .major):      .init(name: .b, tonality: .minor)
        case (.dSharp, .major): .init(name: .c, tonality: .minor)
        case (.e, .major):      .init(name: .cSharp, tonality: .minor)
        case (.f, .major):      .init(name: .d, tonality: .minor)
        case (.fSharp, .major): .init(name: .dSharp, tonality: .minor)
        case (.g, .major):      .init(name: .e, tonality: .minor)
        case (.gSharp, .major): .init(name: .f, tonality: .minor)
        case (.a, .major):      .init(name: .fSharp, tonality: .minor)
        case (.aSharp, .major): .init(name: .g, tonality: .minor)
        case (.b, .major):      .init(name: .gSharp, tonality: .minor)
        // --- Minor to Major
        case (.a, .minor):      .init(name: .c, tonality: .major)
        case (.aSharp, .minor): .init(name: .cSharp, tonality: .major)
        case (.b, .minor):      .init(name: .d, tonality: .major)
        case (.c, .minor):      .init(name: .dSharp, tonality: .major)
        case (.cSharp, .minor): .init(name: .e, tonality: .major)
        case (.d, .minor):      .init(name: .f, tonality: .major)
        case (.dSharp, .minor): .init(name: .fSharp, tonality: .major)
        case (.e, .minor):      .init(name: .g, tonality: .major)
        case (.f, .minor):      .init(name: .gSharp, tonality: .major)
        case (.fSharp, .minor): .init(name: .a, tonality: .major)
        case (.g, .minor):      .init(name: .aSharp, tonality: .major)
        case (.gSharp, .minor): .init(name: .b, tonality: .major)
        // --- Fallback for .unknown tonality — no relative key exists ---
        default:
            .init(name: name, tonality: tonality)
        }
    }
}

// swiftformat:enable consecutiveSpaces
