// Copyright Ryan Francesconi. All Rights Reserved. Revision History at
// https://github.com/ryanfrancesconi/spfk-audio-content-analysis

import Foundation

public enum Modality: Sendable, Hashable, Equatable, CustomStringConvertible {
    case major
    case minor
    case unknown

    public var description: String {
        switch self {
        case .major:
            "Major"
        case .minor:
            "Minor"
        case .unknown:
            ""
        }
    }
}
