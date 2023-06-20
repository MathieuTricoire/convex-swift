import ConvexWebSocket
import SwiftUI

public protocol ConvexQueryDescriptionProtocol {
    var path: CanonicalizedUdfPath { get }
}

public struct ConvexQueryDescription: ConvexQueryDescriptionProtocol {
    public private(set) var path: CanonicalizedUdfPath

    public init(path: CanonicalizedUdfPath) {
        self.path = path
    }
}

public struct ConvexQueries {
    static let shared = ConvexQueries()

    private init() {}
}

// TODO: Tests put app in background/foreground, closing opening to see how ws behaves...

// use autoConnect: false to not start the query immediately and provide a connect function
// possible to do a version with multiple queries? i.e. with a dict?

@MainActor
public final class QueryLoader: ObservableObject {
    @Published internal var value: ConvexValue?
    @Published public var subscribed: Bool = false

    private var path: CanonicalizedUdfPath
    private var args: FunctionArgs?
    private var subscriber: QuerySubscriber?

    // a isLoading for paginated query?

    deinit {
        print("deinit query loader")
    }

    init(path: CanonicalizedUdfPath, args: FunctionArgs?) {
        print("init query loader")
        self.path = path
        self.args = args
    }

    public func subscribe(client: ConvexClient?) {
        guard let client else {
            fatalError("Could not find Convex client! Please provide one with the `convexClient` modifier.")
        }

        guard subscriber == nil else { return }
        subscriber = client.subscriber(path: path, args: args, resultHandler: { [weak self] newValue in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.value = newValue
            }
        })
        subscriber!.subscribe()
        subscribed = true
    }

    public func updateArgs(args: FunctionArgs?) {
        self.args = args

        guard let subscriber else { return }
        subscriber.updateArgs(args: args)
    }

    public func unsubscribe() {
        subscriber = nil
        subscribed = false
    }
}

@propertyWrapper public struct ConvexQuery<Query: ConvexQueryDescriptionProtocol>: DynamicProperty {
    @Environment(\.convexClient) var client
    @StateObject var queryLoader: QueryLoader

    private let subscribeMode: SubscribeMode

    // optional onError closure to let user decide how to behave when receiving an error from Convex?
    // don't know how yet but user will be able to handle the error and if it want to update result or not, if want to hide messages for example should return an empty array or null depending of the state value of ConvexQuery otherwise if we want to keep previous value it return the `previousValue` value unchanged from the closure.
    // i.e. this closure will be (error: Error, previousValue: ConvexValue) -> ConvexValue?

    public var wrappedValue: ConvexValue? {
        queryLoader.value
    }

    public var projectedValue: QueryLoader {
        queryLoader
    }

    public enum SubscribeMode {
        case auto
        case manual
    }

    public init(_ keyPath: KeyPath<ConvexQueries, Query>, args: FunctionArgs? = nil, subscribe subscribeMode: SubscribeMode = .auto) {
        let path = ConvexQueries.shared[keyPath: keyPath].path
        self.subscribeMode = subscribeMode
        _queryLoader = StateObject(wrappedValue: QueryLoader(path: path, args: args))
    }

    public func update() {
        if !queryLoader.subscribed, subscribeMode == .auto {
            queryLoader.subscribe(client: client)
        }
    }
}
