@testable import Convex
import TestHelpers
import XCTest

// swiftlint:disable line_length
private let base64Image = "/9j/4AAQSkZJRgABAQAASABIAAD/4QCARXhpZgAATU0AKgAAAAgABAESAAMAAAABAAEAAAEaAAUAAAABAAAAPgEbAAUAAAABAAAARodpAAQAAAABAAAATgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAAAygAwAEAAAAAQAAAAwAAAAA/8AAEQgADAAMAwEiAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/bAEMAAQEBAQEBAgEBAgMCAgIDBAMDAwMEBgQEBAQEBgcGBgYGBgYHBwcHBwcHBwgICAgICAkJCQkJCwsLCwsLCwsLC//bAEMBAgICAwMDBQMDBQsIBggLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLC//dAAQAAf/aAAwDAQACEQMRAD8A/ef9iT9nX4p/8FDtI1f9sz9snxtr0uh+Lr+/Xw94EtLgWlhpWmRTPFbO4VfPiuiih1aOSKRSQ7NuICSfs0/tTftm/B3TvGPwPHh2++K+l+B/Fep6HpPiG7nUXEthalBHFLLJIGuJISWjeXnLAqSWRq+3Pjr4Atfgt4006/8AhDqN/wCG11p3+029jKFg3SStIzKjKwBLOxHUDOAAK+1Phx8MPCXg/wAKwWEEJvpLj/SZ7i9xLNLLMAWZjgAfRQFHYV+Z1eKq+eZ5i8swVNUa2GbTlzWi4XXIlaN27au60d7N3P23A8RYfLMJ9YzHCwxOErOLp0pKypNKSbVutnZtP395K6Vv/9k="
// swiftlint:enable line_length

final class ValueTests: XCTestCase {
    let object: Value = [
        "_id": .id(id: "messages:r0EqEuw9iXdjESHeXvlL9w"),
        "author": "Mathieu",
        "body": "Hi Convex!",
        "published": true,
        "updatedAt": .null,
        "metadata": [
            "coordinates": [40.7537509, .float(value: -73.9835428)],
        ],
        "social": .map([
            "github": "https://github.com/MathieuTricoire",
        ]),
        "numb3rs": .map([
            .int(99): ["Brooklyn", 99],
        ]),
        "languages": .set(["Swift"]),
        "image": .bytes(Data(base64Encoded: base64Image)!),
    ]

    func testDynamicMember() {
        XCTAssertEqual(object._id, .id(id: "messages:r0EqEuw9iXdjESHeXvlL9w"))
        XCTAssertEqual(object.author, "Mathieu")
        XCTAssertEqual(object.body, .string("Hi Convex!"))
        XCTAssertEqual(object.published, true)
        XCTAssertEqual(object.updatedAt, .null)
        XCTAssertEqual(object.metadata?.coordinates?[0], 40.7537509)
        XCTAssertEqual(object.metadata?.coordinates?[1], .float(-73.9835428))
        XCTAssertEqual(object.social, .map(["github": "https://github.com/MathieuTricoire"]))
        XCTAssertEqual(object.social?.github, "https://github.com/MathieuTricoire")
        XCTAssertEqual(object.numb3rs?[99], ["Brooklyn", 99])
        XCTAssertEqual(object.languages, .set(["Swift"]))
        XCTAssertEqual(object.image, .bytes(Data(base64Encoded: base64Image)!))

        XCTAssertEqual(object.metadata?.coordinates?[2], nil)
        XCTAssertEqual(object.invalid, nil)
        XCTAssertEqual(object.social?.twitter, nil)
        XCTAssertEqual(object.numb3rs?.99, nil) // `99` is a string here, not necessary to support that with a fallback IMHO.
        XCTAssertEqual(object.numb3rs?.98, nil)
    }

    func testSubscript() {
        XCTAssertEqual(object["_id"], .id("messages:r0EqEuw9iXdjESHeXvlL9w"))
        XCTAssertEqual(object["author"], "Mathieu")
        XCTAssertEqual(object["body"], .string("Hi Convex!"))
        XCTAssertEqual(object["published"], true)
        XCTAssertEqual(object["updatedAt"], .null)
        XCTAssertEqual(object["metadata"]?["coordinates"]?[0], 40.7537509)
        XCTAssertEqual(object["metadata"]?["coordinates"]?[1], .float(-73.9835428))
        XCTAssertEqual(object["social"]?["github"], "https://github.com/MathieuTricoire")
        XCTAssertEqual(object["numb3rs"]?[99], ["Brooklyn", 99])
        XCTAssertEqual(object["languages"], .set(["Swift"]))
        XCTAssertEqual(object["image"], .bytes(Data(base64Encoded: base64Image)!))

        XCTAssertEqual(object["invalid"], nil)
        XCTAssertEqual(object["metadata"]?["coordinates"]?[2], nil)
        XCTAssertEqual(object["social"]?["twitter"], nil)
        XCTAssertEqual(object["numb3rs"]?[98], nil)
    }
}
