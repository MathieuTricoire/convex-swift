import Convex
import Foundation

struct StateVersion: Decodable, Equatable {
    let querySet: QueryId
    let identity: IdentityVersion
    let timestamp: ConvexTimestamp

    enum CodingKeys: String, CodingKey {
        case querySet
        case identity
        case timestamp = "ts"
    }

    init() {
        querySet = 0
        identity = 0
        timestamp = .init()
    }

    init(querySet: QueryId, identity: IdentityVersion, timestamp: ConvexTimestamp) {
        self.querySet = querySet
        self.identity = identity
        self.timestamp = timestamp
    }
}

enum ServerMessage: Decodable, Equatable {
    case transition(Transition)
    case mutationResponse(MutationResponse)
    case actionResponse(ActionResponse)
    case authError(AuthError)
    case fatalError(FatalError)
    case ping

    struct Transition: Decodable, Equatable {
        let startVersion: StateVersion
        let endVersion: StateVersion
        let modifications: [StateModification]
    }

    enum StateModification: Decodable, Equatable {
        case updated(QueryUpdated)
        case failed(QueryFailed)
        case removed(QueryRemoved)

        struct QueryUpdated: Decodable, Equatable {
            let queryId: QueryId
            let value: ConvexValue
            let logLines: LogLines
            let journal: QueryJournal
        }

        struct QueryFailed: Decodable, Equatable {
            let queryId: QueryId
            let errorMessage: String
            let logLines: LogLines
            let journal: QueryJournal
        }

        struct QueryRemoved: Decodable, Equatable {
            let queryId: QueryId
        }

        enum CodingKeys: String, CodingKey {
            case type
        }

        enum ModificationType: String, Decodable {
            case updated = "QueryUpdated"
            case failed = "QueryFailed"
            case removed = "QueryRemoved"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(ModificationType.self, forKey: .type)

            switch type {
            case .updated:
                self = try .updated(QueryUpdated(from: decoder))
            case .failed:
                self = try .failed(QueryFailed(from: decoder))
            case .removed:
                self = try .removed(QueryRemoved(from: decoder))
            }
        }
    }

    enum MutationResponse: Decodable, Equatable {
        case success(Success)
        case failed(Failed)

        struct Success: Decodable, Equatable {
            let requestId: RequestId
            let result: ConvexValue
            let timestamp: ConvexTimestamp
            let logLines: LogLines

            enum CodingKeys: String, CodingKey {
                case requestId
                case result
                case timestamp = "ts"
                case logLines
            }
        }

        struct Failed: Decodable, Equatable {
            let requestId: RequestId
            let result: String // TODO rename as error or something else?
            let logLines: LogLines
        }

        var requestId: RequestId {
            switch self {
            case let .success(success):
                return success.requestId
            case let .failed(failed):
                return failed.requestId
            }
        }

        enum CodingKeys: String, CodingKey {
            case success
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let success = try container.decode(Bool.self, forKey: .success)

            switch success {
            case true:
                self = try .success(Success(from: decoder))
            case false:
                self = try .failed(Failed(from: decoder))
            }
        }
    }

    enum ActionResponse: Decodable, Equatable {
        case success(Success)
        case failed(Failed)

        struct Success: Decodable, Equatable {
            let requestId: RequestId
            let result: ConvexValue
            let logLines: LogLines
        }

        struct Failed: Decodable, Equatable {
            let requestId: RequestId
            let result: String // TODO rename as error or something else?
            let logLines: LogLines
        }

        var requestId: RequestId {
            switch self {
            case let .success(success):
                return success.requestId
            case let .failed(failed):
                return failed.requestId
            }
        }

        enum CodingKeys: String, CodingKey {
            case success
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let success = try container.decode(Bool.self, forKey: .success)

            switch success {
            case true:
                self = try .success(Success(from: decoder))
            case false:
                self = try .failed(Failed(from: decoder))
            }
        }
    }

    struct AuthError: Decodable, Error, LocalizedError, Equatable {
        let errorDescription: String?

        enum CodingKeys: String, CodingKey {
            case errorDescription = "error"
        }
    }

    struct FatalError: Decodable, Error, LocalizedError, Equatable {
        let errorDescription: String?

        enum CodingKeys: String, CodingKey {
            case errorDescription = "error"
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
    }

    enum MessageType: String, Decodable {
        case transition = "Transition"
        case mutationResponse = "MutationResponse"
        case actionReponse = "ActionResponse"
        case authError = "AuthError"
        case fatalError = "FatalError"
        case ping = "Ping"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(MessageType.self, forKey: .type)

        switch type {
        case .transition:
            self = try .transition(Transition(from: decoder))
        case .mutationResponse:
            self = try .mutationResponse(MutationResponse(from: decoder))
        case .actionReponse:
            self = try .actionResponse(ActionResponse(from: decoder))
        case .authError:
            self = try .authError(AuthError(from: decoder))
        case .fatalError:
            self = try .fatalError(FatalError(from: decoder))
        case .ping:
            self = .ping
        }
    }
}
