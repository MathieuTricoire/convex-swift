import Foundation

// TODO: Make it sendable...
@dynamicMemberLookup
public enum ConvexValue: Equatable, Hashable, Sendable {
    case id(ConvexId)
    case null
    case int(Int64)
    case float(Double)
    case bool(Bool)
    case string(String)
    case bytes(Data)
    indirect case array([ConvexValue])
    indirect case set(Set<ConvexValue>)
    indirect case map([ConvexValue: ConvexValue])
    indirect case object([String: ConvexValue])
}

public extension ConvexValue {
    subscript(index: Int) -> ConvexValue? {
        switch self {
        case let .array(array):
            return array.indices.contains(index) ? array[index] : nil
        case let .map(map):
            return map[.int(Int64(index))]
        default:
            return nil
        }
    }

    subscript(key: String) -> ConvexValue? {
        switch self {
        case let .object(object):
            return object[key]
        case let .map(map):
            return map[.string(key)]
        default:
            return nil
        }
    }

    subscript(dynamicMember member: String) -> ConvexValue? {
        self[member]
    }

    subscript(dynamicMember member: Int) -> ConvexValue? {
        self[member]
    }
}

struct ImmediateDecodingError: Error {
    var underlyingError: Error

    init(_ error: Error) {
        underlyingError = error
    }
}

enum ConvexCodableError: Error {
    case invalidFieldName(FieldNameError)
}

extension ConvexValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .id(value):
            return value.description
        case .null:
            return "`null`"
        case let .int(value):
            return value.description
        case let .float(value):
            return value.description
        case let .bool(value):
            return value.description
        case let .string(value):
            return value.description
        case let .bytes(value):
            return value.description
        case let .array(value):
            return value.description
        case let .set(value):
            return value.description
        case let .map(value):
            return value.description
        case let .object(value):
            return value.description
        }
    }
}

extension ConvexValue: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .id(value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case let .int(value):
            try container.encode(value)
        case let .float(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case let .string(value):
            try container.encode(value)
        case let .bytes(value):
            try container.encode(ConvexBytes(value))
        case let .array(value):
            try container.encode(value)
        case let .set(value):
            try container.encode(ConvexSet(value))
        case let .map(value):
            try container.encode(ConvexMap(value))
        case let .object(value):
            try container.encode(ConvexObject(value))
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let id = try container.convexDecode(ConvexId.self) {
            self = .id(id)
        } else if let convexMap = try container.convexDecode(ConvexMap.self) {
            self = .map(convexMap.entries)
        } else if let convexSet = try container.convexDecode(ConvexSet.self) {
            self = .set(convexSet.entries)
        } else if let bytes = try container.convexDecode(ConvexBytes.self) {
            self = .bytes(bytes.data)
        } else if let array = try container.convexDecode([ConvexValue].self) {
            self = .array(array)
        } else if let object = try container.convexDecode([String: ConvexValue].self) {
            self = .object(object)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int64.self) {
            self = .int(int)
        } else if let float = try? container.decode(Double.self) {
            self = .float(float)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Invalid Convex value.")
            )
        }
    }
}

extension SingleValueDecodingContainer {
    func convexDecode<T>(_ type: T.Type) throws -> T? where T: Decodable {
        do {
            return try decode(type)
        } catch let immediateError as ImmediateDecodingError {
            throw immediateError.underlyingError
        } catch {
            return nil
        }
    }
}

// MARK: Convex proxy types

struct ConvexMap: Codable {
    let entries: [ConvexValue: ConvexValue]

    init(_ entries: [ConvexValue: ConvexValue]) {
        self.entries = entries
    }

    enum CodingKeys: String, CodingKey {
        case entries = "$map"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var nestedContainer = container.nestedUnkeyedContainer(forKey: .entries)
        for (key, value) in entries {
            try nestedContainer.encode([key, value])
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var arrayContainer = try container.nestedUnkeyedContainer(forKey: .entries)
        var entries: [ConvexValue: ConvexValue] = .init(minimumCapacity: arrayContainer.count ?? 0)
        while !arrayContainer.isAtEnd {
            let tuple: [ConvexValue]
            do {
                tuple = try arrayContainer.decode([ConvexValue].self)
                guard tuple.count == 2 else {
                    throw DecodingError.dataCorrupted(
                        .init(codingPath: arrayContainer.codingPath, debugDescription: "Invalid Convex Map value, expected a tuple representing a key and a value.")
                    )
                }
            } catch {
                throw ImmediateDecodingError(error)
            }
            entries[tuple[0]] = tuple[1]
        }
        self.entries = entries
    }
}

struct ConvexSet: Codable {
    let entries: Set<ConvexValue>

    init(_ entries: Set<ConvexValue>) {
        self.entries = entries
    }

    enum CodingKeys: String, CodingKey {
        case entries = "$set"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entries, forKey: .entries)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let isConvexSet = container.contains(.entries)
        do {
            entries = try container.decode(Set<ConvexValue>.self, forKey: .entries)
        } catch {
            if isConvexSet {
                throw ImmediateDecodingError(error)
            } else {
                throw error
            }
        }
    }
}

struct ConvexBytes: Codable {
    let data: Data

    init(_ data: Data) {
        self.data = data
    }

    enum CodingKeys: String, CodingKey {
        case bytes = "$bytes"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .bytes)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let isConvexBytes = container.contains(.bytes)
        do {
            data = try container.decode(Data.self, forKey: .bytes)
        } catch {
            if isConvexBytes {
                throw ImmediateDecodingError(error)
            } else {
                throw error
            }
        }
    }
}

struct ConvexObject: Codable {
    let entries: [String: ConvexValue]

    init(_ entries: [String: ConvexValue]) {
        self.entries = entries
    }

    struct AnyCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init(_ string: String) {
            stringValue = string
        }

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        for (key, value) in entries {
            try validateObjectField(key)
            try container.encode(value, forKey: AnyCodingKey(key))
        }
    }

    public init(from decoder: Decoder) throws {
        entries = try [String: ConvexValue].init(from: decoder)
    }
}

// MARK: ExpressibleBy* implementations

extension ConvexValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(Int64(value))
    }
}

extension ConvexValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .float(value)
    }
}

extension ConvexValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension ConvexValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension ConvexValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: ConvexValue...) {
        self = .array(elements)
    }
}

extension ConvexValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, ConvexValue)...) {
        var object: [String: ConvexValue] = [:]
        for (key, value) in elements {
            object[key] = value
        }
        self = .object(object)
    }
}
