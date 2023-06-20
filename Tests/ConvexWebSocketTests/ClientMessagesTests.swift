@testable import ConvexWebSocket
import TestHelpers
import XCTest

final class ClientMessagesTests: XCTestCase {
    func test_encode_QuerySetModification() throws {
        let removeQuery = ClientMessage.ModifyQuerySet.Modification.Remove(queryId: 1)
        let addQuery = ClientMessage.ModifyQuerySet.Modification.Add(
            queryId: 2,
            udfPath: CanonicalizedUdfPath("myQueryToAdd"),
            args: [
                "argument": "value",
            ],
            journal: nil
        )

        let querySetModification = ClientMessage.ModifyQuerySet(
            baseVersion: 3,
            newVersion: 4,
            modifications: [
                .remove(removeQuery),
                .add(addQuery),
            ]
        )

        let expectedJSON = """
        {
            "type": "ModifyQuerySet",
            "baseVersion": 3,
            "newVersion": 4,
            "modifications": [
                {
                    "type": "Remove",
                    "queryId": 1
                },
                {
                    "type": "Add",
                    "queryId": 2,
                    "udfPath": "myQueryToAdd.js:default",
                    "args": [{
                        "argument": "value"
                    }]
                }
            ]
        }
        """

        _ = try performEncode(querySetModification, expectedJSON: expectedJSON)
    }
}
