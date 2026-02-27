import SPFKAudioBase
import SPFKBase
import Testing

@testable import SPFKAudioContentAnalysis

struct MusicalKeyValueTests {
    @Test func rawValueInit() throws {
        var strings = [String]()

        for i in 0 ... 24 {
            guard let value = MusicalKeyValue(keyIndex: Int32(i)) else {
                Log.error(i, "is nil")
                #expect(i == 24)
                continue
            }

            strings.append(value.description)
        }

        for string in strings {
            let value = try #require(MusicalKeyValue(string: string))
            print(value)
        }
    }
}
