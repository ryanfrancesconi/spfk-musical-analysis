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
