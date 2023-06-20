@testable import Convex
import XCTest

final class CanonicalizedUdfPathTests: XCTestCase {
    func test_canonicalizeUdfPath() {
        XCTAssertThrowsError(try CanonicalizedUdfPath(path: "")) { error in
            XCTAssertEqual(
                error.localizedDescription,
                "Impossible to create a canonicalized udf path from an empty string"
            )
        }

        let cases = [
            ("myQuery", "myQuery.js:default", #line),
            ("myQuery.js", "myQuery.js:default", #line),
            ("myQuery:default", "myQuery.js:default", #line),
            ("myQuery.js:default", "myQuery.js:default", #line),

            ("foo/myQuery", "foo/myQuery.js:default", #line),
            ("foo/myQuery.js", "foo/myQuery.js:default", #line),
            ("foo/myQuery:default", "foo/myQuery.js:default", #line),
            ("foo/myQuery.js:default", "foo/myQuery.js:default", #line),

            ("foo/bar/myQuery", "foo/bar/myQuery.js:default", #line),
            ("foo/bar/myQuery.js", "foo/bar/myQuery.js:default", #line),
            ("foo/bar/myQuery:default", "foo/bar/myQuery.js:default", #line),
            ("foo/bar/myQuery.js:default", "foo/bar/myQuery.js:default", #line),

            ("myFunctions:all", "myFunctions.js:all", #line),
            ("myFunctions.js:all", "myFunctions.js:all", #line),

            ("foo/myFunctions:all", "foo/myFunctions.js:all", #line),
            ("foo/myFunctions.js:all", "foo/myFunctions.js:all", #line),

            ("foo/bar/myFunctions:all", "foo/bar/myFunctions.js:all", #line),
            ("foo/bar/myFunctions.js:all", "foo/bar/myFunctions.js:all", #line),

            // Original implementation authorize these scenarios, don't know if it's actually possible '.js' suffix will not be consistent
            ("listMessages:some:all", "listMessages:some.js:all", #line),
            ("listMessages:some.js:all", "listMessages:some.js:all", #line),
            // ("listMessages.js:some:all", "", #line),
            ("foo/listMessages:some:all", "foo/listMessages:some.js:all", #line),
            ("foo/listMessages:some.js:all", "foo/listMessages:some.js:all", #line),
            ("foo/bar/listMessages:some:all", "foo/bar/listMessages:some.js:all", #line),
            ("foo/bar/listMessages:some.js:all", "foo/bar/listMessages:some.js:all", #line),
        ]

        for (path, expected, line) in cases {
            // XCTAssertEqual(try! canonicalizeUdfPath(path), expected, line: UInt(line))
            // TODO: make it work with String like before?
            XCTAssertEqual((try! CanonicalizedUdfPath(path: path)).description, expected, line: UInt(line))
        }
    }
}
