import Foundation

enum HanText {
    static func isHanOnly(_ text: String) -> Bool {
        !text.isEmpty && text.allSatisfy(isHanCharacter)
    }

    static func trailingHanRun(in text: String) -> String {
        var characters: [Character] = []
        for character in text.reversed() {
            guard isHanCharacter(character) else { break }
            characters.append(character)
        }
        return String(characters.reversed())
    }

    private static func isHanCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { scalar in
            switch scalar.value {
            case 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF:
                return true
            default:
                return false
            }
        }
    }
}
