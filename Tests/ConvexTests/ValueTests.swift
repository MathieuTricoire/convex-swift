@testable import Convex
import XCTest

// swiftlint:disable line_length
private let base64Image = "/9j/4AAQSkZJRgABAQAASABIAAD/4QCARXhpZgAATU0AKgAAAAgABAESAAMAAAABAAEAAAEaAAUAAAABAAAAPgEbAAUAAAABAAAARodpAAQAAAABAAAATgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAAAygAwAEAAAAAQAAAAwAAAAA/8AAEQgADAAMAwEiAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/bAEMAAQEBAQEBAgEBAgMCAgIDBAMDAwMEBgQEBAQEBgcGBgYGBgYHBwcHBwcHBwgICAgICAkJCQkJCwsLCwsLCwsLC//bAEMBAgICAwMDBQMDBQsIBggLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLC//dAAQAAf/aAAwDAQACEQMRAD8A/ef9iT9nX4p/8FDtI1f9sz9snxtr0uh+Lr+/Xw94EtLgWlhpWmRTPFbO4VfPiuiih1aOSKRSQ7NuICSfs0/tTftm/B3TvGPwPHh2++K+l+B/Fep6HpPiG7nUXEthalBHFLLJIGuJISWjeXnLAqSWRq+3Pjr4Atfgt4006/8AhDqN/wCG11p3+029jKFg3SStIzKjKwBLOxHUDOAAK+1Phx8MPCXg/wAKwWEEJvpLj/SZ7i9xLNLLMAWZjgAfRQFHYV+Z1eKq+eZ5i8swVNUa2GbTlzWi4XXIlaN27au60d7N3P23A8RYfLMJ9YzHCwxOErOLp0pKypNKSbVutnZtP395K6Vv/9k="
// swiftlint:enable line_length

final class ValueTests: XCTestCase {
    let object: ConvexValue = [
        "_id": .id(ConvexId(tableName: "messages", id: "r0EqEuw9iXdjESHeXvlL9w")),
        "author": "Mathieu",
        "body": "Hi Convex!",
        "published": true,
        "updatedAt": .null,
        "metadata": [
            "coordinates": [40.7537509, .float(-73.9835428)],
        ],
        "social": .map([
            "github": "https://github.com/MathieuTricoire",
        ]),
        "numbers": .map([
            .int(99): ["Brooklyn", 99],
        ]),
        "languages": .set(["Swift"]),
        "image": .bytes(Data(base64Encoded: base64Image)!),
    ]

    func testDynamicMember() {
        XCTAssertEqual(object._id, .id(ConvexId(tableName: "messages", id: "r0EqEuw9iXdjESHeXvlL9w")))
        XCTAssertEqual(object.author, "Mathieu")
        XCTAssertEqual(object.body, .string("Hi Convex!"))
        XCTAssertEqual(object.published, true)
        XCTAssertEqual(object.updatedAt, .null)
        XCTAssertEqual(object.metadata?.coordinates?[0], 40.7537509)
        XCTAssertEqual(object.metadata?.coordinates?[1], .float(-73.9835428))
        XCTAssertEqual(object.social, .map(["github": "https://github.com/MathieuTricoire"]))
        XCTAssertEqual(object.social?.github, "https://github.com/MathieuTricoire")
        XCTAssertEqual(object.numbers?[99], ["Brooklyn", 99])
        XCTAssertEqual(object.languages, .set(["Swift"]))
        XCTAssertEqual(object.image, .bytes(Data(base64Encoded: base64Image)!))

        XCTAssertEqual(object.metadata?.coordinates?[2], nil)
        XCTAssertEqual(object.invalid, nil)
        XCTAssertEqual(object.social?.twitter, nil)
        XCTAssertEqual(object.numbers?.99, nil) // `99` is a string here, not necessary to support that with a fallback IMHO.
        XCTAssertEqual(object.numbers?.98, nil)
    }

    func testSubscript() {
        XCTAssertEqual(object["_id"], .id(ConvexId(tableName: "messages", id: "r0EqEuw9iXdjESHeXvlL9w")))
        XCTAssertEqual(object["author"], "Mathieu")
        XCTAssertEqual(object["body"], .string("Hi Convex!"))
        XCTAssertEqual(object["published"], true)
        XCTAssertEqual(object["updatedAt"], .null)
        XCTAssertEqual(object["metadata"]?["coordinates"]?[0], 40.7537509)
        XCTAssertEqual(object["metadata"]?["coordinates"]?[1], .float(-73.9835428))
        XCTAssertEqual(object["social"]?["github"], "https://github.com/MathieuTricoire")
        XCTAssertEqual(object["numbers"]?[99], ["Brooklyn", 99])
        XCTAssertEqual(object["languages"], .set(["Swift"]))
        XCTAssertEqual(object["image"], .bytes(Data(base64Encoded: base64Image)!))

        XCTAssertEqual(object["invalid"], nil)
        XCTAssertEqual(object["metadata"]?["coordinates"]?[2], nil)
        XCTAssertEqual(object["social"]?["twitter"], nil)
        XCTAssertEqual(object["numbers"]?[98], nil)
    }

    func testObject() throws {
        let expectedJSON = """
        {
            "_id": {
                "$id": "messages|r0EqEuw9iXdjESHeXvlL9w"
            },
            "author": "Mathieu",
            "body": "Hi Convex!",
            "published": true,
            "updatedAt": null,
            "metadata": {
                "coordinates": [40.7537509, -73.9835428]
            },
            "social": {
                "$map": [
                    ["github", "https://github.com/MathieuTricoire"]
                ]
            },
            "numbers": {
                "$map": [
                    [99, ["Brooklyn", 99]]
                ]
            },
            "languages": {
                "$set": ["Swift"]
            },
            "image": {
                "$bytes": "\(base64Image)"
            }
        }
        """
        expectRoundTripEquality(object, expectedJSON: expectedJSON)
    }

    func testMultipleMapValues() throws {
        let value: ConvexValue = .map([
            "github": "https://github.com/MathieuTricoire",
            "twitter": "https://twitter.com/tricky21",
        ])
        expectRoundTripEquality(value)
    }

    func testComplicatedMap() throws {
        let value: ConvexValue = .map([
            .object(["unrelated": "stuff"]): .array(["yep it makes no sense", "it's just a test"]),
            "unrelated string": true,
            .map(["unrelated": "map"]): .set(["for an", "unrelated set"]),
        ])
        expectRoundTripEquality(value)
    }

    func testMultipleSetValues() throws {
        let value: ConvexValue = .set([
            "Swift", "Rust", "TypeScript",
        ])
        expectRoundTripEquality(value)
    }

    func testComplicatedSet() throws {
        let value: ConvexValue = .set([
            .object(["name": "Swift"]),
            .object(["name": "Rust"]),
            .object(["name": "TypeScript"]),
            "unrelated string",
            true,
            .map(["one": 1, "two": 2]),
        ])
        expectRoundTripEquality(value)
    }

    // I don't throw an error if a field name is invalid coming from Convex,
    // it should not happen and could be frustrating to not "understand"
    // why it not works (even if error message should indicates that clearly)
    // but I would like opinions on that, and change the behaviour if necessary
    // But we will of course throw an error if we try to encode an invalid field name.
    func testInvalidFieldName() throws {
        // Decode: OK
        let receivedJSON = #"{ "invalid but accepted": true }"#.data(using: .utf8)!
        _ = try performDecode(receivedJSON, type: ConvexValue.self)

        // Encode: ERROR
        let convexToSend: ConvexValue = [
            "invalid and rejected": true,
        ]
        XCTAssertThrowsError(try performEncode(convexToSend)) { error in
            XCTAssertEqual(
                error.localizedDescription,
                #"Field name "invalid and rejected" must only contain alphanumeric characters or underscores and can't start with a number."#
            )
        }
    }
}
