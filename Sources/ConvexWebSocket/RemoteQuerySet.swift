import Convex
import Foundation

class RemoteQuerySet {
    private var version: StateVersion
    private(set) var remoteQueryResults: [QueryId: QueryResult] = [:]

    enum Error: Swift.Error, LocalizedError, Equatable {
        case invalidStartVersion(StateVersion)

        public var errorDescription: String? {
            switch self {
            case let .invalidStartVersion(version):
                return "Invalid start version: \(version.timestamp):\(version.querySet)"
            }
        }
    }

    enum QueryResult {
        case success(ConvexValue)
        case error(String)
    }

    var timestamp: ConvexTimestamp {
        version.timestamp
    }

    init() {
        version = StateVersion()
    }

    func transition(_ transition: ServerMessage.Transition) throws {
        // let start = transition.startVersion
        if version != transition.startVersion {
            throw Error.invalidStartVersion(transition.startVersion)
        }

        for modification in transition.modifications {
            switch modification {
            case let .updated(updated):
                // let path: queryPath(updated.queryId)
                logQuery(updated.queryId, updated.logLines)
                remoteQueryResults[updated.queryId] = .success(updated.value)
            case let .failed(failed):
                logQuery(failed.queryId, failed.logLines)
                remoteQueryResults[failed.queryId] = .error(failed.errorMessage)
            case let .removed(removed):
                remoteQueryResults.removeValue(forKey: removed.queryId)
            }
        }

        version = transition.endVersion
    }

    private func logQuery(_: QueryId, _: LogLines) {
        // TODO:
        // const queryPath = this.queryPath(modification.queryId);
        // if (queryPath) {
        //     for (const line of modification.logLines) {
        //         logToConsole("info", "query", queryPath, line);
        //     }
        // }
    }
}
