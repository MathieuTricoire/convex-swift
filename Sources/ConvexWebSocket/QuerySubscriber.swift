import Convex
import Foundation

public typealias FunctionArgs = [String: ConvexValue]

@MainActor
public final class QuerySubscriber {
    public private(set) var id = Id()
    private weak var client: ConvexClient?
    public private(set) var subscribed: Bool = false
    public private(set) var path: CanonicalizedUdfPath
    public private(set) var args: FunctionArgs?
    private var resultHandler: ResultHandler

    public typealias Id = UUID
    public typealias ResultHandler = (ConvexValue) -> Void

    internal init(client: ConvexClient, path: CanonicalizedUdfPath, args: FunctionArgs?, resultHandler: @escaping ResultHandler) {
        self.client = client
        self.path = path
        self.args = args
        self.resultHandler = resultHandler
        print("init query subscriber \(id)")
    }

    // internal init(client: Client, queryPath: CanonicalizedUdfPath, args: FunctionArgs, resultHandler: @escaping ResultHandler) {
    //     self.client = client
    // internal init(queryPath: CanonicalizedUdfPath, queryArgs: FunctionArgs, resultHandler: @escaping ResultHandler, connectHandler: @escaping ConnectHandler) {
    //     self.connectHandler = connectHandler
    //     self.queryPath = queryPath
    //     self.connect(queryArgs: queryArgs, resultHandler: resultHandler)
    // }

    deinit {
        let id = id
        guard let client else { return }
        Task {
            await client.unsubscribe(subscriberId: id)
        }
    }

    public func subscribe() {
        guard let client else {
            return clientDeinitialized()
        }

        client.subscribe(
            subscriber: self,
            args: args,
            resultHandler: resultHandler
        )
        subscribed = true
    }

    public func updateArgs(args: FunctionArgs?) {
        self.args = args
        if subscribed {
            subscribe()
        }
    }

    public func updateResultHandler(resultHandler: @escaping ResultHandler) {
        self.resultHandler = resultHandler
        if subscribed {
            subscribe()
        }
    }

    // QUID nonisolated here because of deinit in case of fixed actor
    public func unsubscribe() {
        client?.unsubscribe(subscriberId: id)
        subscribed = false
        // cancelHandler? to access private Client function?
        // client?.unsubscribe()
    }

    private func clientDeinitialized() {
        // warning("Client deinitialized")
        subscribed = false
    }
}
