import Foundation

// rename into FunctionPath or ConvexFunction?
// Here or in WebSocket?
public struct CanonicalizedUdfPath: Encodable, Equatable, Hashable, CustomStringConvertible, Sendable {
    public var description: String

    public enum Error: Swift.Error, LocalizedError {
        case empty

        public var errorDescription: String? {
            switch self {
            case .empty:
                return "Impossible to create a canonicalized udf path from an empty string"
            }
        }
    }

    // public init(module: String, function: String?) {
    //     if module.hasSuffix(".js") {
    //         description = "\(module):\(function ?? "default")"
    //     } else {
    //         description = "\(module).js:\(function ?? "default")"
    //     }
    // }

    // public init(module: String) {
    //     self.init(module: module, function: nil)
    // }

    public init(path: String) throws {
        var pieces = path.split(separator: ":")
        let moduleName: Substring
        let functionName: Substring

        switch pieces.count {
        case 0:
            throw Error.empty
        case 1:
            moduleName = pieces.first!
            functionName = "default"
        default:
            functionName = pieces.removeLast()
            moduleName = path[..<pieces.last!.endIndex]
        }

        if moduleName.hasSuffix(".js") {
            description = "\(moduleName):\(functionName)"
        } else {
            description = "\(moduleName).js:\(functionName)"
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension CanonicalizedUdfPath: ExpressibleByStringLiteral {
    public init(stringLiteral path: String) {
        do {
            try self.init(path: path)
        } catch {
            fatalError(error.localizedDescription)
        }
        // var pieces = name.split(separator: ":")
        // let moduleName: Substring
        // let functionName: Substring

        // switch pieces.count {
        // case 0:
        //     fatalError("Impossible to create a canonicalized udf path from an empty string")
        // case 1:
        //     moduleName = pieces.first!
        //     functionName = "default"
        // default:
        //     functionName = pieces.removeLast()
        //     moduleName = name[..<pieces.last!.endIndex]
        // }

        // if moduleName.hasSuffix(".js") {
        //     description = "\(moduleName):\(functionName)"
        // } else {
        //     description = "\(moduleName).js:\(functionName)"
        // }
    }
}
