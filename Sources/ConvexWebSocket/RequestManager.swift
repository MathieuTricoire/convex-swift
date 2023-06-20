import Convex
import Foundation

class RequestManager {
    typealias OnResult = (ConvexValue) -> Void
    typealias OnFailure = (String) -> Void
    typealias OnResolve = () -> Void

    private enum Response {
        case mutation(ServerMessage.MutationResponse)
        case action(ServerMessage.ActionResponse)
    }

    struct CompletionError: Error, LocalizedError {
        var errorDescription: String?
    }

    enum InflightRequest {
        case onGoing(OnGoing)
        case completed(Completed)

        enum Request {
            case mutation(ClientMessage.MutationRequest)
            case action(ClientMessage.ActionRequest)

            var requestId: RequestId {
                switch self {
                case let .mutation(req):
                    return req.requestId
                case let .action(req):
                    return req.requestId
                }
            }

            var udfPath: CanonicalizedUdfPath {
                switch self {
                case let .mutation(req):
                    return req.udfPath
                case let .action(req):
                    return req.udfPath
                }
            }

            // if we store args as a JSON string maybe we could display it in trace log?
            // var args: any Encodable
        }

        struct OnGoing {
            // let onResult: OnResult // Rename onSuccess?
            // let onFailure: OnFailure
            let request: Request
            // Don't really like that...
            var _continuation: CheckedContinuation<ConvexValue, Error>?

            init(request: Request, continuation: CheckedContinuation<ConvexValue, Error>) {
                self.request = request
                _continuation = continuation
            }

            mutating func resolve(value: ConvexValue) {
                // print("[1] resolve continuation", request.requestId, value)
                _continuation?.resume(returning: value)
                _continuation = nil
            }

            mutating func reject(message: String) {
                // print("[2] reject continuation", request.requestId, message)
                _continuation?.resume(throwing: CompletionError(errorDescription: message))
                _continuation = nil
            }
        }

        struct Completed {
            let request: Request
            var _continuation: CheckedContinuation<ConvexValue, Error>?
            let success: ServerMessage.MutationResponse.Success

            init(request: Request, continuation: CheckedContinuation<ConvexValue, Error>?, success: ServerMessage.MutationResponse.Success) {
                self.request = request
                _continuation = continuation
                self.success = success
            }

            var timestamp: ConvexTimestamp {
                success.timestamp
            }

            mutating func resolve() {
                _continuation?.resume(returning: success.result)
                _continuation = nil
            }
        }

        // var incomplete: Bool {
        //     if case .requested = self {
        //         return true
        //     } else {
        //         return false
        //     }
        // }
    }

    // TODO: What about inflightMutations and inflightActions?
    private var ongoingRequests: [RequestId: InflightRequest] = [:]

    // var hasIncompleteRequests: Bool {
    //     ongoingRequests.contains { _, inflightRequest in
    //         inflightRequest.incomplete
    //     }
    // }

    // var hasInflightRequests: Bool {
    //     !ongoingRequests.isEmpty
    // }

    init() {}

    // Rename in waitForCompletion, completion?
    func request(mutationRequest: ClientMessage.MutationRequest) async throws -> ConvexValue {
        try await request(requestId: mutationRequest.requestId, request: .mutation(mutationRequest))
    }

    func request(actionRequest: ClientMessage.ActionRequest) async throws -> ConvexValue {
        try await request(requestId: actionRequest.requestId, request: .action(actionRequest))
    }

    func request(requestId: RequestId, request: InflightRequest.Request) async throws -> ConvexValue {
        try await withCheckedThrowingContinuation { continuation in
            let req = InflightRequest.OnGoing(
                request: request,
                continuation: continuation
            )
            ongoingRequests[requestId] = .onGoing(req)
        }
    }

    func removeAndNotifyCompleted(_ timestamp: ConvexTimestamp) -> Set<RequestId> {
        logger.trace("Remove completed requests at \(timestamp)")
        var completedRequests: Set<RequestId> = Set()
        // print("ongoingRequests", ongoingRequests)
        for (id, inflightRequest) in ongoingRequests {
            if case var .completed(completed) = inflightRequest, completed.timestamp <= timestamp {
                // completed.onResolve()
                logger.trace("Remove completed request: \(completed.request.requestId), path: \(completed.request.udfPath), timestamp: \(completed.timestamp)")
                completed.resolve()
                completedRequests.insert(id)
                ongoingRequests.removeValue(forKey: id)
                // } else {
                // print("nope...")
            }
        }
        return completedRequests
    }

    // TODO: Refactor, Absolutely not satisfied of all `onResponse` handlers...
    func onResponse(mutationResponse: ServerMessage.MutationResponse) -> RequestId? {
        onResponse(requestId: mutationResponse.requestId, response: .mutation(mutationResponse))
    }

    func onResponse(actionResponse: ServerMessage.ActionResponse) {
        onResponse(requestId: actionResponse.requestId, response: .action(actionResponse))
    }

    private func onResponse(requestId: RequestId, response: Response) -> RequestId? {
        guard let inflightRequest = ongoingRequests[requestId] else { return nil }
        var onGoing: InflightRequest.OnGoing
        switch inflightRequest {
        case .completed:
            return nil
        case let .onGoing(req):
            onGoing = req
        }
        if case .action = onGoing.request { return nil }

        // TODO: log lines

        switch response {
        case let .mutation(mutation):
            switch mutation {
            case let .success(success):
                // ongoingRequests[requestId] = .completed(.init(from: &onGoing, success: success))
                ongoingRequests[requestId] = .completed(.init(request: onGoing.request, continuation: onGoing._continuation, success: success))
                return nil
            case let .failed(failed):
                // log...
                // String here?, JavaScript client create a custom string error If I'm right
                // onGoing.onFailure(failed.result)
                onGoing.reject(message: failed.result)
                ongoingRequests.removeValue(forKey: requestId)
                return requestId
            }
        case let .action(action):
            switch action {
            case let .success(success):
                onGoing.resolve(value: success.result)
                ongoingRequests.removeValue(forKey: requestId)
                return requestId
            case let .failed(failed):
                // log...
                // String here?, JavaScript client create a custom string error If I'm right
                // onGoing.onFailure(failed.result)
                onGoing.reject(message: failed.result)
                ongoingRequests.removeValue(forKey: requestId)
                return requestId
            }
        }
    }
}
