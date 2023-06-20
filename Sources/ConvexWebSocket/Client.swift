import Convex
import Foundation

// Client is on the main actor because Tasks order is not guaranteed
// see: https://forums.swift.org/t/task-is-order-of-task-execution-deterministic/51553
// This can be a problem for queries where the order of subscribe and unsubscribe matters
// so for now the client is bound to the main actor (main thread) to guarantee that "queries" messages are sent in order.
@MainActor
public class ConvexClient {
    private var wsManager: WebSocketManager!

    private let state = LocalSyncState()
    private let remoteQuerySet = RemoteQuerySet()
    private let requestManager = RequestManager()
    // TODO: OptimisticQueryResults

    private var _currentRequestId: UInt = 0
    private let sessionId = UUID()

    // TODO: Use a Deque collection: https://github.com/apple/swift-collections/blob/main/Documentation/Deque.md
    private var outgoingMessageQueue: [ClientMessage] = []

    public init(_ baseURL: URL) throws {
        wsManager = try WebSocketManager(
            baseURL,
            client: self
        )

        /*
         wsManager = try WebSocketManager(baseURL)
         wsManager.serverOpenHandler = { [unowned self] connectionCount, lastCloseReason in
             await onOpen(connectionCount: connectionCount, lastCloseReason: lastCloseReason)
         }
         wsManager.serverMessageHandler = { [unowned self] data in
             onMessage(data)
         }
         */

        // // TODO Not connect immediately but only when needed? (let wsManager manages itself)
        // Task {
        //     await wsManager.connect()
        // }
    }

    deinit {
        print("deinit Client")
        // TODO
        guard let wsManager = wsManager else { return }
        Task {
            await wsManager.close()
        }
    }

    public func connect() async {
        await wsManager.connect()
    }

    public func subscriber(path: CanonicalizedUdfPath, args: FunctionArgs?, resultHandler: @escaping (ConvexValue) -> Void) -> QuerySubscriber {
        QuerySubscriber(client: self, path: path, args: args, resultHandler: resultHandler)
    }

    func subscribe(subscriber: QuerySubscriber, args: FunctionArgs?, resultHandler: @escaping QuerySubscriber.ResultHandler) {
        print(1)
        let result = state.subscribe(subscriber: subscriber, args: args, resultHandler: resultHandler)

        if let modifyQuerySet = result.modifyQuerySet {
        print(11, modifyQuerySet)
            sendMessage(.modifyQuerySet(modifyQuerySet))
        }

        print(2, result)
        guard let queryId = result.existingQueryId else { return }
        print(3)
        guard let queryResult = remoteQuerySet.remoteQueryResults[queryId] else { return }
        print(4)
        switch queryResult {
        case let .success(value):
            resultHandler(value)
        default:
            // TODO:
            break
        }
    }

    func unsubscribe(subscriberId: QuerySubscriber.Id) {
        if let modifyQuerySet = state.unsubscribe(subscriberId: subscriberId) {
            // TODO: How to handle this error but more importantly migrate to outgoingMessageQueue
            sendMessage(.modifyQuerySet(modifyQuerySet))
        }
    }

    public func mutation(_ path: CanonicalizedUdfPath, _ args: FunctionArgs? = nil, optimisticUpdate _: String = "TODO") async throws -> ConvexValue {
        let requestId = nextRequestId()

        // TODO: Optimistic update

        let mutationRequest = ClientMessage.MutationRequest(
            requestId: requestId,
            path: path,
            args: args
        )

        // TODO: Is this exception necessary

        // In TypeScript there is no suspension here and so we are sure that we will register the "inflight" request before receiving the response, here it's not the case...
        // let sent = try wsManager.sendMessage(mutationRequest)
        sendMessage(.mutationRequest(mutationRequest))

        return try await requestManager.request(mutationRequest: mutationRequest)
    }

    public func action(_ path: CanonicalizedUdfPath, _ args: FunctionArgs? = nil) async throws -> ConvexValue {
        let requestId = nextRequestId()

        let actionRequest = ClientMessage.ActionRequest(
            requestId: requestId,
            path: path,
            args: args
        )
        sendMessage(.actionRequest(actionRequest))

        return try await requestManager.request(actionRequest: actionRequest)
    }

    private func sendMessage(_ message: ClientMessage) {
        outgoingMessageQueue.append(message)
        // print()
        // print("outgoingMessageQueue", outgoingMessageQueue)
        // print()
        wsManager.flushMessages()
    }

    private func nextRequestId() -> UInt {
        // If I'm correct request id start with 0 in JavaScript impl.
        // I don't like currentRequestId, I don't like nextRequestId too but it's may be better...
        let id = _currentRequestId
        _currentRequestId += 1
        return id
    }

    private func notifyQueryResultChanges(queryIds: Set<QueryId>, optimisticUpdateRequestsToDrop _: Set<RequestId>) {
        for queryId in queryIds {
            guard let result = remoteQuerySet.remoteQueryResults[queryId] else { continue }
            switch result {
            case let .success(value):
                guard let handlers = state.resultHandlers[queryId] else { continue }
                for (_, handler) in handlers {
                    handler(value)
                }
            case .error:
                // TODO:
                break
            }
        }
    }

    func onOpen(connectionCount: UInt, lastCloseReason: String?) {
        sendMessage(.connect(ClientMessage.Connect(sessionId: sessionId, connectionCount: connectionCount, lastCloseReason: lastCloseReason)))
    }

    // TODO: fix that, @MainActor is a Temp fix to be sure we do not have concurrent access to the client
    // @MainActor
    // Seems working even if removing but I'm pretty sure it should not, I need to print thread for every methods in the client (do precondition)
    func onMessage(message: ServerMessage) {
        // print("onMessage thread:", Thread.current, Thread.current.isMainThread)
    
        switch message {
        case let .transition(transition):
            // authenticationManager.onTransition(serverMessage);

            // TODO: Handle the try exception?
            try? remoteQuerySet.transition(transition)

            // convex-rs (need to check convex-js) do that differently, they recompute all queries and compare with a local result to notify updated query results
            // I do it this wa thinking it's more performant but certainly not having all the information this is not done this way for reasons that's why it's not in transition function for now and external
            var updatedQueryIds: Set<QueryId> = []
            for modification in transition.modifications {
                switch modification {
                case let .updated(updated):
                    updatedQueryIds.update(with: updated.queryId)
                case let .failed(failed):
                    updatedQueryIds.update(with: failed.queryId)
                case let .removed(removed):
                    updatedQueryIds.update(with: removed.queryId)
                }
            }
            // add to this updatedQueryIds ids for query impacted by outdated optimistic updates for completed requests?

            // this.state.saveQueryJournals(serverMessage);

            let completedRequests = requestManager.removeAndNotifyCompleted(remoteQuerySet.timestamp)

            notifyQueryResultChanges(queryIds: updatedQueryIds, optimisticUpdateRequestsToDrop: completedRequests)
        case let .mutationResponse(mutationResponse):
            // const completedMutationId =
            //     this.requestManager.onResponse(serverMessage);
            // if (completedMutationId) {
            //     this.notifyQueryResultChanges(new Set([completedMutationId]));
            // }
            let completedMutationId = requestManager.onResponse(mutationResponse: mutationResponse)
            // What if we receive mutationResponse before transition?
            if let completedMutationId {
                notifyQueryResultChanges(queryIds: [], optimisticUpdateRequestsToDrop: [completedMutationId])
            }
        case let .actionResponse(actionResponse):
            requestManager.onResponse(actionResponse: actionResponse)
        case .authError:
            // authenticationManager.onAuthError(authError)
            break
        case let .fatalError(fatalError):
            logger.critical("\(fatalError.localizedDescription)")
            Task {
                await wsManager.close()
            }
        // const error = logFatalError(serverMessage.error);
        // void this.webSocketManager.stop();
        // throw error;
        case .ping:
            // logger.trace("Ping")
            break
        }
    }

    func popNextClientMessage() -> ClientMessage? {
        if outgoingMessageQueue.isEmpty { return nil }
        return outgoingMessageQueue.removeFirst()
    }
}
