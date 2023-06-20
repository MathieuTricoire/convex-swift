@testable import ConvexWebSocket
import TestHelpers
import XCTest

final class ServerMessagesTests: XCTestCase {
    func test_decode_Transition() throws {
        let json = """
        {
            "type": "Transition",
            "startVersion": {
                "querySet": 0,
                "identity": 0,
                "ts": "AAAAAAAAAAA="
            },
            "endVersion": {
                "querySet": 1,
                "identity": 0,
                "ts": "XaBqFyQzVRc="
            },
            "modifications": [
                {
                    "type": "QueryUpdated",
                    "queryId": 0,
                    "value": [
                        {
                            "_creationTime": 1680103614845.8333,
                            "_id": {
                                "$id": "messages|4kKVm3KQ8mLgc3yhvI9L9Q"
                            },
                            "author": "Mathieu",
                            "body": "Hello"
                        },
                        {
                            "_creationTime": 1681289465931.0574,
                            "_id": {
                                "$id": "messages|luQuaU4M3FbSrtd-RLZMAw"
                            },
                            "author": "Mathieu",
                            "body": "World!"
                        }
                    ],
                    "logLines": [],
                    "journal": null
                },
                {
                    "type": "QueryRemoved",
                    "queryId": 1
                },
                {
                    "type": "QueryFailed",
                    "queryId": 2,
                    "errorMessage": "query 2 has failed",
                    "logLines": [],
                    "journal": null
                }
            ]
        }
        """.data(using: .utf8)!

        let message = try performDecode(json, type: ServerMessage.self)

        let expectedMessage = ServerMessage.transition(.init(
            startVersion: .init(querySet: 0, identity: 0, timestamp: "AAAAAAAAAAA="),
            endVersion: .init(querySet: 1, identity: 0, timestamp: "XaBqFyQzVRc="),
            modifications: [
                .updated(.init(
                    queryId: 0,
                    value: .array([
                        .object([
                            "_creationTime": 1_680_103_614_845.8333,
                            "_id": .id("messages|4kKVm3KQ8mLgc3yhvI9L9Q"),
                            "author": "Mathieu",
                            "body": "Hello",
                        ]),
                        .object([
                            "_creationTime": 1_681_289_465_931.0574,
                            "_id": .id("messages|luQuaU4M3FbSrtd-RLZMAw"),
                            "author": "Mathieu",
                            "body": "World!",
                        ]),
                    ]),
                    logLines: [],
                    journal: nil
                )),
                .removed(.init(queryId: 1)),
                .failed(.init(
                    queryId: 2,
                    errorMessage: "query 2 has failed",
                    logLines: [],
                    journal: nil
                )),
            ]
        ))

        XCTAssertEqual(message, expectedMessage)
    }

    func test_decode_MutationResponseSuccess() throws {
        let json = """
        {
            "type": "MutationResponse",
            "mutationId": 0,
            "requestId": 0,
            "success": true,
            "result": {
                "executionTime": 1234
            },
            "ts": "XaXIZoH7WBc=",
            "logLines": []
        }
        """.data(using: .utf8)!

        let message = try performDecode(json, type: ServerMessage.self)

        let expectedMessage = ServerMessage.mutationResponse(.success(.init(
            requestId: 0,
            result: ["executionTime": 1234],
            timestamp: "XaXIZoH7WBc=",
            logLines: []
        )))

        XCTAssertEqual(message, expectedMessage)
    }

    func test_decode_empty_MutationResponseSuccess() throws {
        let json = """
        {
            "type": "MutationResponse",
            "requestId": 1,
            "success": true,
            "result": null,
            "ts": "XaXIZoH7WBc=",
            "logLines": [
                "log entry 1",
                "log entry 2"
            ]
        }
        """.data(using: .utf8)!

        let message = try performDecode(json, type: ServerMessage.self)

        let expectedMessage = ServerMessage.mutationResponse(.success(.init(
            requestId: 1,
            result: .null,
            timestamp: "XaXIZoH7WBc=",
            logLines: [
                "log entry 1",
                "log entry 2",
            ]
        )))

        XCTAssertEqual(message, expectedMessage)
    }

    func test_decode_MutationResponseFailed() throws {
        let json = """
        {
            "type": "MutationResponse",
            "mutationId": 2,
            "requestId": 2,
            "success": false,
            "result": "Cannot complete this mutation",
            "logLines": [
                "log entry 1",
                "log entry 2"
            ]
        }
        """.data(using: .utf8)!

        let message = try performDecode(json, type: ServerMessage.self)

        // TODO: Check on Convex how errors behaves.
        let expectedMessage = ServerMessage.mutationResponse(.failed(.init(
            requestId: 2,
            result: "Cannot complete this mutation",
            logLines: [
                "log entry 1",
                "log entry 2",
            ]
        )))

        XCTAssertEqual(message, expectedMessage)
    }

    func test_decode_ActionResponseSuccess() throws {
        let json = """
        {
            "type": "ActionResponse",
            "actionId": 3,
            "requestId": 3,
            "success": true,
            "result": "Completed",
            "logLines": []
        }
        """.data(using: .utf8)!

        let message = try performDecode(json, type: ServerMessage.self)

        let expectedMessage = ServerMessage.actionResponse(.success(.init(
            requestId: 3,
            result: "Completed",
            logLines: []
        )))

        XCTAssertEqual(message, expectedMessage)
    }

    func test_decode_empty_ActionResponseSuccess() throws {
        let json = """
        {
            "type": "ActionResponse",
            "requestId": 4,
            "success": true,
            "result": null,
            "logLines": [
                "log entry 1",
                "log entry 2"
            ]
        }
        """.data(using: .utf8)!

        let message = try performDecode(json, type: ServerMessage.self)

        let expectedMessage = ServerMessage.actionResponse(.success(.init(
            requestId: 4,
            result: .null,
            logLines: [
                "log entry 1",
                "log entry 2",
            ]
        )))

        XCTAssertEqual(message, expectedMessage)
    }

    func test_decode_ActionResponseFailed() throws {
        let json = """
        {
            "type": "ActionResponse",
            "requestId": 5,
            "success": false,
            "result": "Cannot complete this action",
            "logLines": [
                "log entry 1",
                "log entry 2"
            ]
        }
        """.data(using: .utf8)!

        let message = try performDecode(json, type: ServerMessage.self)

        // TODO: Check on Convex how errors behaves.
        let expectedMessage = ServerMessage.actionResponse(.failed(.init(
            requestId: 5,
            result: "Cannot complete this action",
            logLines: [
                "log entry 1",
                "log entry 2",
            ]
        )))

        XCTAssertEqual(message, expectedMessage)
    }
}
