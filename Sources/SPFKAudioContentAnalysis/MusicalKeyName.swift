import Foundation

public enum MusicalKeyName: Int32, Sendable, Hashable, Equatable, CustomStringConvertible {
    case c = 0
    case cSharp
    case d
    case dSharp
    case e
    case f
    case fSharp
    case g
    case gSharp
    case a
    case aSharp
    case b

    public var description: String {
        switch self {
        case .c:
            "C"
        case .cSharp:
            "C#"
        case .d:
            "D"
        case .dSharp:
            "D#"
        case .e:
            "E"
        case .f:
            "F"
        case .fSharp:
            "F#"
        case .g:
            "G"
        case .gSharp:
            "G#"
        case .a:
            "A"
        case .aSharp:
            "A#"
        case .b:
            "B"
        }
    }
}
