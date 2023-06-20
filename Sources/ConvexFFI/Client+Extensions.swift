public extension Client {
    func subscribe(path: String, args: [String: Value], resultHandler: @escaping (Value) -> Void) async throws -> Subscription {
        let callback = SubscribeCallback(resultHandler)
        return try await self.subscribe(path: path, args: args, callback: callback)
    }
}

class SubscribeCallback: Callback {
    let resultHandler: (Value) -> Void

    init(_ resultHandler: @escaping (Value) -> Void) {
        self.resultHandler = resultHandler
    } 

    func update(value: Value) {
        resultHandler(value)
    }
}
