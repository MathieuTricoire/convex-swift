@testable import Convex
import XCTest

final class ValidateObjectFieldTests: XCTestCase {
    func testThrowEmpty() throws {
        XCTAssertThrowsError(try validateObjectField("")) { error in
            XCTAssertEqual(error as! FieldNameError, FieldNameError.empty)
            XCTAssertEqual(error.localizedDescription, "Empty field names are disallowed.")
        }
    }

    func testThrowTooLong() throws {
        let field = "it_should_throw_an_error_because_it_is_sixty_five_characters_long"
        XCTAssertThrowsError(try validateObjectField(field)) { error in
            XCTAssertEqual(error as! FieldNameError, FieldNameError.tooLong(field))
            XCTAssertEqual(error.localizedDescription, "Field name \"\(field)\" exceeds maximum field name length 64.")
        }
    }

    func testThrowReservedDollarPrefix() throws {
        let field = "$thisIsReserved"
        XCTAssertThrowsError(try validateObjectField(field)) { error in
            XCTAssertEqual(error as! FieldNameError, FieldNameError.reservedDollarPrefix("$thisIsReserved"))
            XCTAssertEqual(error.localizedDescription, "Field name \"\(field)\" starts with a '$', which is reserved.")
        }
    }

    func testThrowAllUnderscores() throws {
        XCTAssertThrowsError(try validateObjectField("_")) { error in
            XCTAssertEqual(error as! FieldNameError, FieldNameError.allUnderscores("_"))
        }
        XCTAssertThrowsError(try validateObjectField("__")) { error in
            XCTAssertEqual(error as! FieldNameError, FieldNameError.allUnderscores("__"))
            XCTAssertEqual(error.localizedDescription, #"Field name "__" can't exclusively be underscores."#)
        }
    }

    func testThrowInvalidCharacters() throws {
        XCTAssertThrowsError(try validateObjectField(" ")) { error in
            XCTAssertEqual(error as! FieldNameError, FieldNameError.invalidCharacters(" "))
            XCTAssertEqual(
                error.localizedDescription,
                #"Field name " " must only contain alphanumeric characters or underscores and can't start with a number."#
            )
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
            "_maybe_that_should_throw_but_its_accepted_in_other_Convex_client", // 64 chars starting with `_`
        ]
        for field in fields {
            try validateObjectField(field)
        }
    }
}
