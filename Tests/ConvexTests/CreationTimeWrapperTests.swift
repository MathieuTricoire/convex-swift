@testable import Convex
import XCTest

final class CreationTimeWrapperTests: XCTestCase {
    struct MyDocument: Decodable {
        @ConvexCreationTime var _creationTime: Date
    }

    func test() throws {
        let jsonData = """
        {
            "_creationTime": 1680520937620.8
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let doc = try decoder.decode(MyDocument.self, from: jsonData)

        let expectedDate = Date(timeIntervalSince1970: 1_680_520_937.6208)
        XCTAssertEqual(doc._creationTime, expectedDate)
        XCTAssertEqual(doc._creationTime.ISO8601Format(), "2023-04-03T11:22:17Z")
        XCTAssertEqual(expectedDate.ISO8601Format(), "2023-04-03T11:22:17Z")
    }
}
