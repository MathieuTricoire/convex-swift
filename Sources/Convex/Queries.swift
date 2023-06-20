import SwiftUI
import ConvexFFI

public protocol ConvexQueryDescriptionProtocol {
    var path: String { get }
}

public struct ConvexQueryDescription: ConvexQueryDescriptionProtocol {
    public private(set) var path: String

    public init(path: String) {
        self.path = path
    }
}

public struct ConvexQueries {
    static let shared = ConvexQueries()

    private init() {}
}

@MainActor
public final class QueryLoader: ObservableObject {
    @Published internal var value: Value?
    @Published public var subscribed = false

    public var subscribing = false

    private var path: String
    private var args: [String: Value]
    private var subscription: Subscription?

    init(path: String, args: [String: Value]) {
        self.path = path
        self.args = args
    }

    public func subscribe(client: Client?) {
        guard let client else {
            fatalError("Could not find Convex client! Please provide one with the `convexClient` modifier.")
        }

        subscribing = true
        Task {
            subscription = try? await client.subscribe(path: path, args: args, resultHandler: { [weak self] newValue in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.value = newValue
                }
            })
            subscribing = false
            subscribed = true
        }
    }

    public func unsubscribe() {
        subscription = nil
        subscribed = false
    }
}

@propertyWrapper public struct ConvexQuery<Query: ConvexQueryDescriptionProtocol>: DynamicProperty {
    @Environment(\.convexClient) var client
    @StateObject var queryLoader: QueryLoader

    public var wrappedValue: Value? {
        queryLoader.value
    }

    public var projectedValue: QueryLoader {
        queryLoader
    }

    public init(_ keyPath: KeyPath<ConvexQueries, Query>, args: [String: Value]? = nil) {
        let path = ConvexQueries.shared[keyPath: keyPath].path
        _queryLoader = StateObject(wrappedValue: QueryLoader(path: path, args: args ?? [:]))
    }

    public func update() {
        if !queryLoader.subscribed && !queryLoader.subscribing {
            queryLoader.subscribe(client: client)
        }
    }
}
