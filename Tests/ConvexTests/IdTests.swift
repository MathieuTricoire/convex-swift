@testable import Convex
import TestHelpers
import XCTest

final class IdTests: XCTestCase {
    func testEncode() throws {
        let id = ConvexId(tableName: "messages", id: "r0EqEuw9iXdjESHeXvlL9w")
        let encoder = JSONEncoder()
        let encodedId = try encoder.encode(id)

        let encodedIdString = String(decoding: encodedId, as: UTF8.self)
        XCTAssertEqual(encodedIdString, #"{"$id":"messages|r0EqEuw9iXdjESHeXvlL9w"}"#)
    }

    func testDecode() throws {
        let encodedId = """
        {
            "$id": "messages|r0EqEuw9iXdjESHeXvlL9w"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let id = try decoder.decode(ConvexId.self, from: encodedId)

        let expectedId = ConvexId(tableName: "messages", id: "r0EqEuw9iXdjESHeXvlL9w")
        XCTAssertEqual(id, expectedId)
    }

    func testThrowErrorIfInvalidFormat() {
        let json = """
        {
            "$id": "messages-r0EqEuw9iXdjESHeXvlL9w",
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try performDecode(json, type: ConvexId.self)) { error in
            let immediateError = error as! ImmediateDecodingError
            let underlyingError = immediateError.underlyingError as! DecodingError
            guard case let DecodingError.dataCorrupted(error) = underlyingError else {
                return XCTFail("Expected a DecodingError.dataCorrupted error")
            }
            XCTAssertEqual(error.debugDescription, "Invalid $id format")
        }
    }
}
