import Foundation

// TODO Ping Pong

actor WebSocketManager {
    let url: URL

    var wsTask: URLSessionWebSocketTask
    var encoder = JSONEncoder()

    // TODO: More a ConvexState than a WebSocket State? i.e. if connect done then can do thing...
    var state = State.disconnected
    private var connectionCount: UInt = 0
    private var lastCloseReason: String? = "InitialConnect"
    private let decoder = JSONDecoder()

    private var flushingMessages = false

    private var initialBackoff: Double = 0.1
    private var maxBackoff: Double = 16
    private var retries = 0
    private unowned var client: ConvexClient

    // Check if it could be a unowned?
    // may be we can use owned because the delegate to the url session is not a strong ref.
    // (i.e. not self and the need to invalidate the session)
    // so url session should be deinit as soon as the manager is deinited, and the manager
    // being strongly referenced only by the client, it would mean that once the client is
    // deinited so manager will be too so there is no need to check if the delegate exists
    // or not (i.e. weak) because it should be impossible to call a nil delegate.
    // explain this correctly in comments and be sure to make "Manager" private...

    // var popNextClientMessage: () async -> ClientMessage?
    // var serverOpenHandler: (UInt, String?) async -> Void
    // var serverMessageHandler: (Data) -> Void

    enum State {
        case disconnected, connecting, ready, closing, pausing, paused, stopping, stopped
    }

    public init(
        _ baseURL: URL,
        client: ConvexClient
    ) throws {
        url = try webSocketURL(baseURL)
        self.client = client
        let wsDelegate = WebSocketManagerSessionDelegate()
        let session = URLSession(configuration: .default, delegate: wsDelegate, delegateQueue: nil)
        wsTask = session.webSocketTask(with: url)
        wsDelegate.wsManager = self

        // Task { [weak self] in
        //     guard let self else { return }
        //     await connect()
        // }
    }

    deinit {
        print("deinit WebSocketManager")
        // close()
    }

    func connect() async {
        // print("connecting, current state:", state)

        if state == .closing || state == .stopping || state == .stopped { return }
        if state != .disconnected, state != .paused {
            return
                // TODO:
                // throw new Error("Didn't start connection from disconnected state");
        }

        // QUID Mock...
        // wsTask = session!.webSocketTask(with: url)
        // wsTask = URLSession.shared.webSocketTask(with: url)
        wsTask.resume()

        // const ws = new this.webSocketConstructor(this.uri);
        // this._logVerbose("constructed WebSocket");
        // this.socket = {
        // state: "connecting",
        // ws,
        // };
        state = .connecting

        // NB: The WebSocket API calls `onclose` even if connection fails, so we can route all error paths through `onclose`.
        // ws.onerror = error => {
        //     const message = (error as ErrorEvent).message;
        //     console.log(`WebSocket error: ${message}`);
        //     this.closeAndReconnect("WebSocketError");
        // };
        // ws.onmessage = message => {
        //     // TODO(CX-1498): We reset the retry counter on any successful message.
        //     // This is not ideal and we should improve this further.
        //     this.retries = 0;
        //     this.onServerActivity();
        //     const serverMessage = parseServerMessage(JSON.parse(message.data));
        //     this._logVerbose(`received ws message with type ${serverMessage.type}`);
        //     this.onMessage(serverMessage);
        // };
    }

    func resume() async throws {
        switch state {
        case .pausing:
            break
        // TODO:
        // await this.socket.promisePair.promise
        case .paused:
            break
        case .stopping, .stopped:
            // If we're stopping we ignore resume
            return
        case .connecting, .ready, .closing, .disconnected:
            // TODO:
            // throw new Error("`resume()` is only valid after `pause()`");
            return
        }
        await connect()
    }

    func close() {
        logger.trace("close WebSocket")
        // if (reconnectDueToServerInactivityTimeout) {
        //   clearTimeout(this.reconnectDueToServerInactivityTimeout);
        // }
        switch state {
        case .stopped:
            // print("WebSocket stopped")
            break
        case .connecting, .ready:
            // print("WebSocketManager: close (connecting, ready)")
            // this.socket.ws.close();
            // this.socket = {
            //   state: "stopping",
            //   promisePair: promisePair(),
            // };
            // await this.socket.promisePair.promise;
            wsTask.cancel()
            state = .stopping
        case .pausing, .closing:
            // print("WebSocketManager: close (pausing, closing)")
            // We're already closing the WebSocket, so just upgrade the state
            // to "stopping" so we don't reconnect.
            // this.socket = {
            //   state: "stopping",
            //   promisePair: promisePair(),
            // };
            // await this.socket.promisePair.promise;
            state = .stopping
        case .paused, .disconnected:
            // print("WebSocketManager: close (paused, disconnected)")
            // If we're disconnected so switch the state to "stopped" so the reconnect
            // timeout doesn't create a new WebSocket.
            // If we're paused prevent a resume.
            // this.socket = { state: "stopped" };
            state = .stopped
        case .stopping:
            // print("WebSocketManager: close (stopping)")
            // await this.socket.promisePair.promise;
            break
        }
        // wsTask = nil

        // session.finishTasksAndInvalidate()
        // a Task to invalidateAndCancel() after X seconds?
    }

    private func onServerActivity() {
        // if (this.reconnectDueToServerInactivityTimeout !== null) {
        //     clearTimeout(this.reconnectDueToServerInactivityTimeout);
        //     this.reconnectDueToServerInactivityTimeout = null;
        // }
        // this.reconnectDueToServerInactivityTimeout = setTimeout(() => {
        //     this.closeAndReconnect("InactiveServer");
        // }, this.serverInactivityThreshold);
    }

    // Probably better return Duration
    private func nextBackoff() -> TimeInterval {
        let baseBackoff = initialBackoff * pow(2, Double(retries))
        retries += 1
        let actualBackoff = min(baseBackoff, maxBackoff)
        let jitter = actualBackoff * Double.random(in: 0 ... 0.5)
        return actualBackoff + jitter
    }

    // TODO: should not need session, webSocketTask and negotiatedProtocol.
    func onOpen(_: URLSession, _: URLSessionWebSocketTask, _: String?) async {
        logger.trace("WebSocket opened")
        // self.onOpen()
        // self.state = "connected"
        // self.sendQueuedMessages()

        // this._logVerbose("begin ws.onopen");
        if state != .connecting {
            return
                // TODO: Cannot throw here, what to do...
                // throw new Error("onopen called with socket not in connecting state");
        }
        // this.socket = { state: "ready", ws };
        state = .ready

        // this.onServerActivity();
        await client.onOpen(connectionCount: connectionCount, lastCloseReason: lastCloseReason)
        // await serverOpenHandler(connectionCount, lastCloseReason)

        // if (this.lastCloseReason !== "InitialConnect") {
        //     console.log("WebSocket reconnected");
        // }

        // wsTask.receive(completionHandler: onMessage)
        setReceiveHandler()

        connectionCount += 1
        lastCloseReason = nil
    }

    // TODO: should not need session and webSocketTask.
    func onClose(_: URLSession, _: URLSessionWebSocketTask, _ closeCode: URLSessionWebSocketTask.CloseCode, _ reasonData: Data?) async {
        let reason = reasonData.map { String(decoding: $0, as: UTF8.self) }

        if lastCloseReason == nil {
            lastCloseReason = reason ?? "OnCloseInvoked"
        }

        // NOTE: Cannot handle custom Convex code: 4040 "Not found" (4XXX codes are authorized for private use)
        // Current Foundation implementation will fallback to code: 1003 "Unsupported data"
        // So I include this code as an unexpected close code even if in JavaScript impl it's not the case.
        if ![.normalClosure, .goingAway, .noStatusReceived, .unsupportedData].contains(closeCode) {
            logger.trace("WebSocket closed unexpectedly with code: \(closeCode), reason: \(reason ?? "(unknown)")")
        } else {
            logger.trace("WebSocket closed with code: \(closeCode), reason: \(reason ?? "(unknown)")")
        }

        if state == .stopping {
            // this.socket.promisePair.resolve(null);
            state = .stopped
            return
        }

        if state == .pausing {
            // this.socket.promisePair.resolve(null);
            // this.socket = { state: "paused" };
            state = .paused
            return
        }

        state = .disconnected
        // this.socket = { state: "disconnected" };
        // let backoff = nextBackoff()
        // console.log(`Attempting reconnect in ${backoff}ms`);
        // print("Attempting reconnect in \(backoff)");
        // TODO: Strong self?
        // try? await Task.sleep(for: backoff)
        await connect()
    }

    // TO REMOVE
    func setReceiveHandler() {
        // wsTask.receive(completionHandler: onMessage)

        logger.trace("WebSocket raw value state: \(wsTask.state.rawValue)")
        // print("[setReceiveHandler] WsTask state:", wsTask.state.rawValue, "state:", state)
        // try debugging...
        if wsTask.state == .running {
            wsTask.receive(completionHandler: onMessage)
        }
    }

    // TO REMOVE
    func onMessage(_ result: Result<URLSessionWebSocketTask.Message, Error>) {
        // print("[onMessage] set handler again")
        defer { self.setReceiveHandler() }

        switch result {
        case let .success(message):

            // TODO(CX-1498): We reset the retry counter on any successful message.
            // This is not ideal and we should improve this further.
            retries = 0
            onServerActivity()
            // const serverMessage = parseServerMessage(JSON.parse(message.data));
            // this._logVerbose(`received ws message with type ${serverMessage.type}`);
            // this.onMessage(serverMessage);

            switch message {
            case let .string(string):
                let message = try? decoder.decode(ServerMessage.self, from: Data(string.utf8))
                guard let message else { return }
                Task {
                    await client.onMessage(message: message)
                }
            case .data:
                // print("[onMessage] Message data:", data)
                // print("[onMessage] Message data string:", String(decoding: data, as: UTF8.self))
                break
            @unknown default:
                break
                // print("[onMessage] Unknown message received")
            }

        case let .failure(error):
            print("[onMessage] Error:", error)
        }
    }

    // How to send the message from another thread (i.e. to encode on another thread at least)
    // and making call sequential (i.e. not async and no order guarantee)
    func sendMessage(_ message: some Encodable) throws -> Bool {
        guard state == .ready else {
            // print("[sendMessage] State is not ready, don't send message")
            return false
        }

        // TODO: Encoder here or upfront in Client? i.e. server messages are actually decoded in client, maybe here we should remove everything about the message, we should pass a `URLSessionWebSocketTask.Message` .string(String) for the wsTask
        let encodedMessage = try encoder.encode(message)
        let messageStr = String(data: encodedMessage, encoding: .utf8)!
        // print("[sendMessage] Message Str:", messageStr)
        // wsTask.send(.string(messageStr)) { error in
        //     print("send completed, error?:", error)
        // }

        // TODO: Handle result...
        wsTask.send(.string(messageStr), completionHandler: { _ in })
        // // TODO: JS version is not async, what happens if message is not send, many things to check in this function
        // do {
        //     try await wsTask.send(.string(messageStr))
        //     // print("[sendMessage] Message sent succesfully")
        // } catch {
        //     // print("[sendMessage] Failed to send message on WebSocket, error: \(error)")
        //     // TODO: Close and reconnect
        // }
        // // We are not sure if this was sent or not.
        return true
    }

    nonisolated func flushMessages() {
        Task {
            await _flushMessages()
        }
    }

    private func _flushMessages() async {
        if flushingMessages { return }

        flushingMessages = true
        while let message = await client.popNextClientMessage() {
            // QUID initial connect client message to send...
            if state == .disconnected {
                print("disconnected...")
                await connect()
            }
            try? await Task.sleep(for: .milliseconds(100))
            let result = try? sendMessage(message)
            print("send message", message, result)
        }
        flushingMessages = false
    }
}

class WebSocketManagerSessionDelegate: NSObject, URLSessionWebSocketDelegate {
    weak var wsManager: WebSocketManager?

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol: String?) {
        Task {
            await wsManager?.onOpen(session, webSocketTask, didOpenWithProtocol)
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task {
            await wsManager?.onClose(session, webSocketTask, didCloseWith, reason)
        }
    }
}

func webSocketURL(_ baseURL: URL) throws -> URL {
    guard var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
        throw URLError(.badURL)
    }

    switch urlComponents.scheme {
    case "http":
        urlComponents.scheme = "ws"
    default:
        urlComponents.scheme = "wss"
    }

    // TODO: Rust client doesn't use api version, directly connect to `api/sync`?
    urlComponents.path = "/api/sync"
    if let url = urlComponents.url {
        return url
    } else {
        throw URLError(.badURL)
    }
}
