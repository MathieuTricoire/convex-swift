/// Special type to define a type as nullable,
/// an optional type would not be send and so no modifications will happens on Convex side.
/// a null value will "unset" and so delete the value.
/// Subject to change if it makes more sense to not handle these `null` values.
public enum ConvexNullable<T: Codable> {
    case defined(T)
    case null
}

extension ConvexNullable: Equatable where T: Equatable {}

extension ConvexNullable: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .defined(value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else {
            self = try .defined(container.decode(T.self))
        }
    }
}

extension ConvexNullable: ExpressibleByNilLiteral {
    public init(nilLiteral _: ()) {
        self = .null
    }
}

extension ConvexNullable: ExpressibleByIntegerLiteral where T == Int {
    public init(integerLiteral value: Int) {
        self = .defined(Int(value))
    }
}

extension ConvexNullable: ExpressibleByFloatLiteral where T == Double {
    public init(floatLiteral value: Double) {
        self = .defined(value)
    }
}

extension ConvexNullable: ExpressibleByBooleanLiteral where T == Bool {
    public init(booleanLiteral value: Bool) {
        self = .defined(value)
    }
}

extension ConvexNullable: ExpressibleByStringLiteral, ExpressibleByUnicodeScalarLiteral, ExpressibleByExtendedGraphemeClusterLiteral where T == String {
    public init(stringLiteral value: T.StringLiteralType) {
        self = .defined(value)
    }

    public init(unicodeScalarLiteral value: T.UnicodeScalarLiteralType) {
        self = .defined(value)
    }

    public init(extendedGraphemeClusterLiteral value: T.ExtendedGraphemeClusterLiteralType) {
        self = .defined(value)
    }
}
