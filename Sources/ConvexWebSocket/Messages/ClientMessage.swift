import Convex
import Foundation

enum ClientMessage: Encodable, Sendable {
    case connect(Connect)
    case modifyQuerySet(ModifyQuerySet)
    case mutationRequest(MutationRequest)
    case actionRequest(ActionRequest)
    // case authenticate(Authenticate)
    // case event(Event)

    func encode(to encoder: Encoder) throws {
        switch self {
        case let .connect(connect):
            try connect.encode(to: encoder)
        case let .modifyQuerySet(modifyQuerySet):
            try modifyQuerySet.encode(to: encoder)
        case let .mutationRequest(mutationRequest):
            try mutationRequest.encode(to: encoder)
        case let .actionRequest(actionRequest):
            try actionRequest.encode(to: encoder)
        }
    }

    public struct Connect: Encodable {
        let type = "Connect"
        var sessionId: UUID
        var connectionCount: UInt
        var lastCloseReason: String?
    }

    struct ModifyQuerySet: Encodable {
        let type = "ModifyQuerySet"
        var baseVersion: QuerySetVersion
        var newVersion: QuerySetVersion
        var modifications: [Modification]

        enum Modification: Encodable {
            case add(Add)
            case remove(Remove)

            public struct Add: Encodable {
                var queryId: QueryId
                var udfPath: CanonicalizedUdfPath
                var args: FunctionArgs
                var journal: QueryJournal

                init(queryId: QueryId, udfPath: CanonicalizedUdfPath, args: FunctionArgs?, journal: QueryJournal) {
                    self.queryId = queryId
                    self.udfPath = udfPath
                    self.args = args ?? [:]
                    self.journal = journal
                }

                enum CodingKeys: String, CodingKey {
                    case type
                    case queryId
                    case udfPath
                    case args
                    case journal
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode("Add", forKey: .type)
                    try container.encode(queryId, forKey: .queryId)
                    try container.encode(udfPath, forKey: .udfPath)
                    // TODO: If I don't do that it will encode journal as null, good to know...
                    if let journal {
                        try container.encode(journal, forKey: .journal)
                    }
                    var argsContainer = container.nestedUnkeyedContainer(forKey: .args)
                    try argsContainer.encode(args)

                    // Maybe I'll need to encode it this way in the future, if Convex accept the args object direclty instead of an array with one args object since the change in 0.13
                    // Same for MutationRequest and ActionRequest
                    // let argsEncoder = container.superEncoder(forKey: .args)
                    // try args.encode(to: argsEncoder)
                }
            }

            public struct Remove: Encodable {
                let type = "Remove"
                var queryId: QueryId
            }

            func encode(to encoder: Encoder) throws {
                switch self {
                case let .add(add):
                    try add.encode(to: encoder)
                case let .remove(remove):
                    try remove.encode(to: encoder)
                }
            }
        }
    }

    struct MutationRequest: Encodable {
        var requestId: RequestId
        var udfPath: CanonicalizedUdfPath
        var args: FunctionArgs

        init(requestId: RequestId, path: CanonicalizedUdfPath, args: FunctionArgs?) {
            self.requestId = requestId
            udfPath = path
            self.args = args ?? [:]
        }

        enum CodingKeys: String, CodingKey {
            case type
            case requestId
            case udfPath
            case args
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("Mutation", forKey: .type)
            try container.encode(requestId, forKey: .requestId)
            try container.encode(udfPath, forKey: .udfPath)
            var argsContainer = container.nestedUnkeyedContainer(forKey: .args)
            try argsContainer.encode(args)
        }
    }

    struct ActionRequest: Encodable {
        var requestId: RequestId
        var udfPath: CanonicalizedUdfPath
        var args: FunctionArgs

        init(requestId: RequestId, path: CanonicalizedUdfPath, args: FunctionArgs?) {
            self.requestId = requestId
            udfPath = path
            self.args = args ?? [:]
        }

        enum CodingKeys: String, CodingKey {
            case type
            case requestId
            case udfPath
            case args
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("Action", forKey: .type)
            try container.encode(requestId, forKey: .requestId)
            try container.encode(udfPath, forKey: .udfPath)
            var argsContainer = container.nestedUnkeyedContainer(forKey: .args)
            try argsContainer.encode(args)
        }
    }
}
