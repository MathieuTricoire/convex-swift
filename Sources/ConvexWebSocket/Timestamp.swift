import Foundation

// TODO: Rename Timestamp
struct ConvexTimestamp: Equatable, Hashable {
    let timestamp: UInt64

    static let max = UInt64(UInt64.max)
    static let expectedBytesCount = MemoryLayout<UInt64>.size

    enum Error: Swift.Error, LocalizedError {
        case invalidBytes
        case outOfBounds(UInt64)

        var errorDescription: String? {
            switch self {
            case .invalidBytes:
                return "Expected a \(ConvexTimestamp.expectedBytesCount) bytes Base64 string representing a convex timestamp."
            case let .outOfBounds(value):
                return "Timestamp \(value) out of bounds"
            }
        }
    }

    init(value: UInt64) throws {
        if value > Self.max {
            throw Error.outOfBounds(value)
        }
        timestamp = value
    }

    init(data: Data) throws {
        if data.count != Self.expectedBytesCount {
            throw Error.invalidBytes
        }
        try self.init(value: data.withUnsafeBytes { $0.load(as: UInt64.self).littleEndian })
    }

    init() {
        timestamp = 0
    }
}

extension ConvexTimestamp: Comparable {
    static func < (lhs: ConvexTimestamp, rhs: ConvexTimestamp) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
}

extension ConvexTimestamp: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)

        do {
            try self.init(data: data)
        } catch {
            throw DecodingError.dataCorrupted(
                .init(codingPath: container.codingPath, debugDescription: error.localizedDescription)
            )
        }
    }
}

extension ConvexTimestamp: CustomStringConvertible {
    var description: String {
        withUnsafeBytes(of: timestamp.littleEndian) { Data($0) }.base64EncodedString()
    }
}

extension ConvexTimestamp: ExpressibleByStringLiteral {
    init(stringLiteral value: StringLiteralType) {
        guard let data = Data(base64Encoded: value) else {
            fatalError("Timestamp string literal is not a valid convex timestamp, expected a \(ConvexTimestamp.expectedBytesCount) bytes Base64 string")
        }

        do {
            try self.init(data: data)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
