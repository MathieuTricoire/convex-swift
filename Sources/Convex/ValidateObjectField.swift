import Foundation
import RegexBuilder

let maxIdentifierLen = 64

// Use this when regex literal will not require an unsafe flag...
// let allUnderscoresRegex = /^_+$/
// let identifierRegex = /^[a-zA-Z_][\w]{0,63}$/
let allUnderscoresRegex = Regex {
    OneOrMore {
        "_"
    }
}
let identifierRegex = Regex {
    CharacterClass(
        .anyOf("_"),
        ("a"..."z"),
        ("A"..."Z")
    )
    Repeat(0...63) {
        One(.word)
    }
}

func validateObjectField(_ fieldName: String) throws {
    if fieldName.count == 0 {
        throw FieldNameError.empty
    }
    if fieldName.count > maxIdentifierLen {
        throw FieldNameError.tooLong(fieldName)
    }
    if fieldName.hasPrefix("$") {
        throw FieldNameError.reservedDollarPrefix(fieldName)
    }
    if fieldName.wholeMatch(of: allUnderscoresRegex) != nil {
        throw FieldNameError.allUnderscores(fieldName)
    }
    if fieldName.wholeMatch(of: identifierRegex) == nil {
        throw FieldNameError.invalidCharacters(fieldName)
    }
}

enum FieldNameError: Error, Equatable {
    case empty, tooLong(String), reservedDollarPrefix(String), allUnderscores(String), invalidCharacters(String)
}

extension FieldNameError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Empty field names are disallowed."
        case let .tooLong(fieldName):
            return "Field name \"\(fieldName)\" exceeds maximum field name length \(maxIdentifierLen)."
        case let .reservedDollarPrefix(fieldName):
            return "Field name \"\(fieldName)\" starts with a '$', which is reserved."
        case let .allUnderscores(fieldName):
            return "Field name \"\(fieldName)\" can't exclusively be underscores."
        case let .invalidCharacters(fieldName):
            return "Field name \"\(fieldName)\" must only contain alphanumeric characters or underscores and can't start with a number."
        }
    }
}

extension FieldNameError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .empty:
            return NSLocalizedString(description, comment: "Empty field")
        case .tooLong:
            return NSLocalizedString(description, comment: "Too long")
        case .reservedDollarPrefix:
            return NSLocalizedString(description, comment: "Reserverd `$` prefix")
        case .allUnderscores:
            return NSLocalizedString(description, comment: "All underscores")
        case .invalidCharacters:
            return NSLocalizedString(description, comment: "Invalid characters")
        }
    }
}
