@testable import Convex
import XCTest

struct Message: Codable, Equatable {
    var _id: ConvexId
    @ConvexCreationTime
    var _creationTime: Date
    var author: String
    var body: String
    var backgroundColor: ConvexNullable<String>
    var foregroundColor: ConvexNullable<String>
}

final class ValueTypedTests: XCTestCase {
    func testCodable() throws {
        let value = Message(
            _id: ConvexId(tableName: "messages", id: "r0EqEuw9iXdjESHeXvlL9w"),
            _creationTime: Date(timeIntervalSince1970: 1_680_520_937.6208),
            author: "Mathieu",
            body: "Hi Convex!",
            backgroundColor: nil,
            foregroundColor: "red"
        )
        let expectedJSON = """
        {
            "_id": {
                "$id": "messages|r0EqEuw9iXdjESHeXvlL9w"
            },
            "_creationTime": 1680520937620.8,
            "author": "Mathieu",
            "body": "Hi Convex!",
            "backgroundColor": null,
            "foregroundColor": "red"
        }
        """
        expectRoundTripEquality(value, expectedJSON: expectedJSON)
    }
}
