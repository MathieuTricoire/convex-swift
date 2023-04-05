import Foundation

@propertyWrapper
public struct ConvexCreationTime: Codable, Equatable {
    private let value: Double
    public var wrappedValue: Date

    public init(wrappedValue: Date) {
        self.wrappedValue = wrappedValue
        value = wrappedValue.timeIntervalSince1970 * 1000
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(Double.self)
        wrappedValue = Date(timeIntervalSince1970: value / 1000)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
