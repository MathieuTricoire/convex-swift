import Foundation
import XCTest

func performEncode(_ value: some Encodable, expectedJSON: String? = nil, file: StaticString = #file, line: UInt = #line) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .withoutEscapingSlashes
    let encoded = try encoder.encode(value)
    if let expectedJSON {
        XCTAssertEqual(expectedJSON.prettyPrintedJSONString, encoded.prettyPrintedJSONString, file: file, line: line)
    }
    return encoded
}

func performDecode<T: Decodable>(_ value: Data, type _: T.Type, file _: StaticString = #file, line _: UInt = #line) throws -> T {
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: value)
}

func expectRoundTripEquality<T: Codable>(_ value: T, expectedJSON: String? = nil, file: StaticString = #file, line: UInt = #line) where T: Equatable {
    let encoded: Data
    do {
        encoded = try performEncode(value, expectedJSON: expectedJSON, file: file, line: line)
    } catch {
        XCTFail("\(file):\(line): Unable to encode \(T.self) <\(debugDescription(value))>: \(error)", file: file, line: line)
        return
    }

    let decoded: T
    do {
        decoded = try performDecode(encoded, type: T.self, file: file, line: line)
    } catch {
        XCTFail("\(file):\(line): Unable to decode \(T.self) <\(debugDescription(value))>: \(error)", file: file, line: line)
        return
    }

    XCTAssertEqual(value, decoded, "\(#file):\(line): Decoded \(T.self) <\(debugDescription(decoded))> not equal to original <\(debugDescription(value))>", file: file, line: line)
}

private func debugDescription(_ value: some Any) -> String {
    if let debugDescribable = value as? CustomDebugStringConvertible {
        return debugDescribable.debugDescription
    } else if let describable = value as? CustomStringConvertible {
        return describable.description
    } else {
        return "\(value)"
    }
}

extension String {
    var prettyPrintedJSONString: String {
        let data = data(using: .utf8)!
        return data.prettyPrintedJSONString
    }
}

extension Data {
    var prettyPrintedJSONString: String {
        let object = try! JSONSerialization.jsonObject(with: self, options: [])
        let data = try! JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        return String(decoding: data, as: UTF8.self)
    }
}
