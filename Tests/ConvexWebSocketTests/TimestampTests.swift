/*
 @testable import ConvexWebSocket
 import XCTest

 final class TimestampTests: XCTestCase {
     func testComparable() {
         let tests: [(lhs: ConvexTimestamp, rhs: ConvexTimestamp, equals: Bool, notEquals: Bool, lt: Bool, lte: Bool, gt: Bool, gte: Bool, UInt, String, String)] = [
             // Equal cases
             ("AAAAAAAAAAA=", "AAAAAAAAAAA=", true, false, false, true, false, true, #line, "AAAAAAAAAAA=", "AAAAAAAAAAA="),
             ("AAAAAAAAAIA=", "AAAAAAAAAIA=", false, true, false, false, true, true, #line, "AAAAAAAAAIA=", "AAAAAAAAAIA="),
             ("AAAAAIAAAAA=", "AAAAAIAAAAA=", true, false, false, true, false, true, #line, "AAAAAIAAAAA=", "AAAAAIAAAAA="),
             ("AAAAgAAAAAA=", "AAAAgAAAAAA=", true, false, false, true, false, true, #line, "AAAAgAAAAAA=", "AAAAgAAAAAA="),
             ("gAAAAAAAAAA=", "gAAAAAAAAAA=", true, false, false, true, false, true, #line, "gAAAAAAAAAA=", "gAAAAAAAAAA="),
             ("AAAAAAAAAAE=", "AAAAAAAAAAE=", true, false, false, true, false, true, #line, "AAAAAAAAAAE=", "AAAAAAAAAAE="),
             ("AAAAAAEAAAA=", "AAAAAAEAAAA=", true, false, false, true, false, true, #line, "AAAAAAEAAAA=", "AAAAAAEAAAA="),
             ("AAAAAQAAAAA=", "AAAAAQAAAAA=", true, false, false, true, false, true, #line, "AAAAAQAAAAA=", "AAAAAQAAAAA="),
             ("AQAAAAAAAAA=", "AQAAAAAAAAA=", true, false, false, true, false, true, #line, "AQAAAAAAAAA=", "AQAAAAAAAAA="),

             // COMP CASES:
             ("AAAAAAAAAIA=", "AAAAAAAAAEA=", false, true, false, false, true, true, #line, "AAAAAAAAAIA=", "AAAAAAAAAEA="),
             ("AAAAAAAAAEA=", "AAAAAAAAAIA=", false, true, true, true, false, false, #line, "AAAAAAAAAEA=", "AAAAAAAAAIA="),
             ("AAAAAIAAAAA=", "AAAAAEAAAAA=", false, true, false, false, true, true, #line, "AAAAAIAAAAA=", "AAAAAEAAAAA="),
             ("AAAAAEAAAAA=", "AAAAAIAAAAA=", false, true, true, true, false, false, #line, "AAAAAEAAAAA=", "AAAAAIAAAAA="),
             ("AAAAgAAAAAA=", "AAAAQAAAAAA=", false, true, false, false, true, true, #line, "AAAAgAAAAAA=", "AAAAQAAAAAA="),
             ("AAAAQAAAAAA=", "AAAAgAAAAAA=", false, true, true, true, false, false, #line, "AAAAQAAAAAA=", "AAAAgAAAAAA="),
             ("gAAAAAAAAAA=", "QAAAAAAAAAA=", false, true, false, false, true, true, #line, "gAAAAAAAAAA=", "QAAAAAAAAAA="),
             ("gAAAAAAAAAA=", "QAAAAAAAAAA=", false, true, false, false, true, true, #line, "gAAAAAAAAAA=", "QAAAAAAAAAA="),
             ("AAAAAAAAAAE=", "AAAAAAAAAAI=", false, true, true, true, false, false, #line, "AAAAAAAAAAE=", "AAAAAAAAAAI="),
             ("AAAAAAAAAAI=", "AAAAAAAAAAE=", false, true, false, false, true, true, #line, "AAAAAAAAAAI=", "AAAAAAAAAAE="),
             ("AAAAAAEAAAA=", "AAAAAAIAAAA=", false, true, true, true, false, false, #line, "AAAAAAEAAAA=", "AAAAAAIAAAA="),
             ("AAAAAAIAAAA=", "AAAAAAEAAAA=", false, true, false, false, true, true, #line, "AAAAAAIAAAA=", "AAAAAAEAAAA="),
             ("AAAAAQAAAAA=", "AAAAAgAAAAA=", false, true, true, true, false, false, #line, "AAAAAQAAAAA=", "AAAAAgAAAAA="),
             ("AAAAAgAAAAA=", "AAAAAQAAAAA=", false, true, false, false, true, true, #line, "AAAAAgAAAAA=", "AAAAAQAAAAA="),
             ("AQAAAAAAAAA=", "AgAAAAAAAAA=", false, true, true, true, false, false, #line, "AQAAAAAAAAA=", "AgAAAAAAAAA="),
             ("AQAAAAAAAAA=", "AgAAAAAAAAA=", false, true, true, true, false, false, #line, "AQAAAAAAAAA=", "AgAAAAAAAAA="),
         ]

         for (lhs, rhs, equals, notEquals, lt, lte, gt, gte, line, l, r) in tests {
             XCTAssertEqual(lhs == rhs, equals, "equals expected to be \(equals)", line: line)
             XCTAssertEqual(lhs != rhs, notEquals, "notEquals expected to be \(notEquals)", line: line)
             XCTAssertEqual(lhs < rhs, lt, "lt expected to be \(lt)", line: line)
             XCTAssertEqual(lhs <= rhs, lte, "lte expected to be \(lte)", line: line)
             XCTAssertEqual(lhs > rhs, gt, "gt expected to be \(gt)", line: line)
             XCTAssertEqual(lhs >= rhs, gte, "gte expected to be \(gte)", line: line)

             XCTAssertEqual(l, lhs.description)
             XCTAssertEqual(r, rhs.description)
         }
     }
 }
 */
