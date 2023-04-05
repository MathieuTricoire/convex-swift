@testable import Convex
import XCTest

final class ValidateObjectFieldTests: XCTestCase {
    func testThrowEmpty() throws {
        XCTAssertThrowsError(try validateObjectField("")) { error in
            XCTAssertEqual(error as! FieldNameError, FieldNameError.empty)
        }
    }

    func testThrowTooLong() throws {
        let field = "it_should_throw_an_error_because_it_is_sixty_five_characters_long"
        XCTAssertThrowsError(try validateObjectField(field)) { error in
            XCTAssertEqual(error as! FieldNameError, FieldNameError.tooLong(field))
        }
    }

    func testThrowReservedDollarPrefix() throws {
        let field = "$thisIsReserved"
        XCTAssertThrowsError(try validateObjectField(field)) { error in
            XCTAssertEqual(error as! FieldNameError, FieldNameError.reservedDollarPrefix("$thisIsReserved"))
        }
    }

    func testThrowAllUnderscores() throws {
        XCTAssertThrowsError(try validateObjectField("_")) { error in
            XCTAssertEqual(error as! FieldNameError, FieldNameError.allUnderscores("_"))
        }
        XCTAssertThrowsError(try validateObjectField("__")) { error in
            XCTAssertEqual(error as! FieldNameError, FieldNameError.allUnderscores("__"))
        }
    }

    func testThrowInvalidCharacters() throws {
        XCTAssertThrowsError(try validateObjectField(" ")) { error in
            XCTAssertEqual(error as! FieldNameError, FieldNameError.invalidCharacters(" "))
        }
        XCTAssertThrowsError(try validateObjectField("99Brooklyn")) { error in
            XCTAssertEqual(error as! FieldNameError, FieldNameError.invalidCharacters("99Brooklyn"))
        }
        XCTAssertThrowsError(try validateObjectField("my-field")) { error in
            XCTAssertEqual(error as! FieldNameError, FieldNameError.invalidCharacters("my-field"))
        }
    }

    func testOk() throws {
        let fields = [
            "_id",
            "_creationTime",
            "Brooklyn99",
            "_maybe_that_should_throw_but_its_accepted_in_other_Convex_client" // 64 chars starting with `_`
        ]
        for field in fields {
            try validateObjectField(field)
        }
    }

}
