import SPFKAudioContentAnalysisC
import Foundation

public struct MusicalKeyValue: Sendable, Hashable, Equatable, CustomStringConvertible {
    public var name: MusicalKeyName
    public var modality: Modality

    public var description: String {
        "\(name) \(modality)"
    }

    public init?(rawValue: Int32) {
        guard rawValue >= 0, rawValue <= 23 else { return nil }
        modality = rawValue > 12 ? .minor : .major

        let nameValue: Int32 = rawValue > 12 ? rawValue - 12 : rawValue
        guard let keyName = MusicalKeyName(rawValue: nameValue) else { return nil }
        name = keyName
    }

    public init(name: MusicalKeyName, modality: Modality) {
        self.name = name
        self.modality = modality
    }

    public init?(cObject: MusicalKey) {
        guard let value = MusicalKeyValue(rawValue: cObject.index) else { return nil }
        
        self = value
    }
    
}
