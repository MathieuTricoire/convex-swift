public struct ConvexId: Hashable, Equatable {
    var tableName: String
    var id: String

    public init(tableName: String, id: String) {
        self.tableName = tableName
        self.id = id
    }
}

extension ConvexId: CustomStringConvertible {
    public var description: String {
        "\(tableName)|\(id)"
    }
}

extension ConvexId: Codable {
    private enum CodingKeys: String, CodingKey {
        case id = "$id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(description, forKey: .id)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idString = try container.decode(String.self, forKey: .id)
        let components = idString.components(separatedBy: "|")
        guard components.count == 2 else {
            throw ImmediateDecodingError(
                DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid $id format")
            )
        }
        tableName = components[0]
        id = components[1]
    }
}

// MARK: ConvexIdentifiable protocol

public protocol ConvexIdentifiable: Identifiable {
    var _id: ConvexId { get }
}

public extension ConvexIdentifiable {
    var id: String {
        _id.description
    }
}
