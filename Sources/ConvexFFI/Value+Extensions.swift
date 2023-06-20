import Foundation

public extension Value {
    subscript(index: Int) -> Value? {
        switch self {
        case let .array(array):
            return array.indices.contains(index) ? array[index] : nil
        case let .map(map):
            return map[.int(Int64(index))]
        default:
            return nil
        }
    }

    subscript(key: String) -> Value? {
        switch self {
        case let .object(object):
            return object[key]
        case let .map(map):
            return map[.string(key)]
        default:
            return nil
        }
    }

    subscript(dynamicMember member: String) -> Value? {
        self[member]
    }

    subscript(dynamicMember member: Int) -> Value? {
        self[member]
    }
}

public extension Value {
    static func id(_ id: String) -> Value {
        return .id(id: id)
    }

    static func int(_ value: Int64) -> Value {
        return .int(value: value)
    }

    static func float(_ value: Double) -> Value {
        return .float(value: value)
    }

    static func bool(_ value: Bool) -> Value {
        return .bool(value: value)
    }

    static func string(_ value: String) -> Value {
        return .string(value: value)
    }

    static func bytes(_ value: Data) -> Value {
        var buf: [UInt8] = []
        buf.append(contentsOf: value)
        return .bytes(value: buf)
    }

    static func array(_ value: [Value]) -> Value {
        return .array(value: value)
    }

    static func set(_ value: [Value]) -> Value {
        return .set(value: value)
    }

    static func map(_ value: [Value: Value]) -> Value {
        return .map(value: value)
    }

    static func object(_ value: [String: Value]) -> Value {
        return .object(value: value)
    }
}

extension Value: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value: Int64(value))
    }
}

extension Value: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .float(value: value)
    }
}

extension Value: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value: value)
    }
}

extension Value: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value: value)
    }
}

extension Value: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Value...) {
        self = .array(value: elements)
    }
}

extension Value: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Value)...) {
        var object: [String: Value] = [:]
        for (key, value) in elements {
            object[key] = value
        }
        self = .object(value: object)
    }
}

extension Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .id(id: value):
            return value.description
        case .null:
            return "`null`"
        case let .int(value: value):
            return value.description
        case let .float(value: value):
            return value.description
        case let .bool(value: value):
            return value.description
        case let .string(value: value):
            return value.description
        case let .bytes(value: value):
            return value.description
        case let .array(value: value):
            return value.description
        case let .set(value: value):
            return value.description
        case let .map(value: value):
            return value.description
        case let .object(value: value):
            return value.description
        }
    }
}