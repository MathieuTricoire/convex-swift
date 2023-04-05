import Foundation
import os

let packageVersion = "0.0.1"

// Special custom 5xx HTTP status code to mean that the UDF returned an error.
let statusCodeUdfFailed = 560

/// Client for communicating with Convex.
public struct Convex {
    public let address: URL
    private var auth: String?
    private var debug: Bool
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
}

struct QueryBody: Encodable {
    let path: String
    let args: [any Encodable]
    let debug: Bool

    enum CodingKeys: String, CodingKey {
        case path
        case args
        case debug
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        var argsContainer = container.nestedUnkeyedContainer(forKey: .args)
        for arg in args {
            try argsContainer.encode(arg)
        }
        try container.encode(debug, forKey: .debug)
    }
}

enum ConvexResponseStatus: String, Decodable {
    case success
    case error
}

struct ConvexResponse<T: Decodable>: Decodable {
    public let status: ConvexResponseStatus
    public let value: T
    public let logLines: [String]
    public let errorMessage: String?
}

enum UDFType: CustomStringConvertible {
    case query, mutation, action

    var path: String {
        switch self {
        case .query:
            return "query"
        case .mutation:
            return "mutation"
        case .action:
            return "action"
        }
    }

    var description: String {
        switch self {
        case .query:
            return "Q"
        case .mutation:
            return "M"
        case .action:
            return "A"
        }
    }
}

enum ConvexError: Error {
    case udfFailed(String)
    case developerError(String)
}

public extension Convex {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: "Convex client")
    )

    init(_ address: URL) {
        self.address = address
        debug = true
        decoder = JSONDecoder()
        encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
    }

    /// Set the authentication token to be used for subsequent queries and mutations.
    ///
    /// Should be called whenever the token changes (i.e. due to expiration and refresh).
    ///
    /// - Parameters:
    ///   - token: JWT-encoded OpenID Connect identity token.
    mutating func setAuth(_ token: String) {
        auth = token
    }

    /// Clear the current authentication token if set.
    mutating func clearAuth() {
        auth = nil
    }

    /// Run a query on Convex and return a decodable value.
    ///
    /// - Parameters:
    ///   - name: The name of the query function.
    ///   - args: A variadic list of ``Encodable``.
    ///
    /// - Returns: `T`
    ///
    /// - Throws:
    ///   - ``ConvexError``
    ///   - ``DecodingError.dataCorrupted`` if values requested from the payload are corrupted, or if the given data is not valid JSON.
    ///   - An error if any value throws an error during decoding.
    func query<T: Decodable>(_ name: String, _ args: any Encodable...) async throws -> T {
        try await _request(.query, name, args)
    }

    /// Run a query on Convex and return the generic ``ConvexValue``
    ///
    /// - Parameters:
    ///   - name: The name of the query function.
    ///   - args: A variadic list of ``Encodable``.
    ///
    /// - Returns: ``ConvexValue``
    ///
    /// - Throws:
    ///   - ``ConvexError```
    ///   - ``DecodingError.dataCorrupted`` if values requested from the payload are corrupted, or if the given data is not valid JSON.
    ///   - An error if any value throws an error during decoding.
    func query(_ name: String, _ args: any Encodable...) async throws -> ConvexValue {
        try await _request(.query, name, args)
    }

    /// Run a mutation on Convex and return a decodable value.
    ///
    /// - Parameters:
    ///   - name: The name of the mutation function.
    ///   - args: A variadic list of ``Encodable``.
    ///
    /// - Returns: `T`
    ///
    /// - Throws:
    ///   - ``ConvexError``
    ///   - ``DecodingError.dataCorrupted`` if values requested from the payload are corrupted, or if the given data is not valid JSON.
    ///   - An error if any value throws an error during decoding.
    func mutation<T: Decodable>(_ name: String, _ args: any Encodable...) async throws -> T {
        try await _request(.mutation, name, args)
    }

    /// Run a mutation on Convex and return the generic ``ConvexValue``
    ///
    /// - Parameters:
    ///   - name: The name of the mutation function.
    ///   - args: A variadic list of ``Encodable``.
    ///
    /// - Returns: ``ConvexValue``
    ///
    /// - Throws:
    ///   - ``ConvexError``
    ///   - ``DecodingError.dataCorrupted`` if values requested from the payload are corrupted, or if the given data is not valid JSON.
    ///   - An error if any value throws an error during decoding.
    @discardableResult
    func mutation(_ name: String, _ args: any Encodable...) async throws -> ConvexValue {
        try await _request(.mutation, name, args)
    }

    /// Run a action on Convex and return a decodable value.
    ///
    /// - Parameters:
    ///   - name: The name of the action function.
    ///   - args: A variadic list of ``Encodable``.
    ///
    /// - Returns: `T`
    ///
    /// - Throws:
    ///   - ``ConvexError``
    ///   - ``DecodingError.dataCorrupted`` if values requested from the payload are corrupted, or if the given data is not valid JSON.
    ///   - An error if any value throws an error during decoding.
    func action<T: Decodable>(_ name: String, _ args: any Encodable...) async throws -> T {
        try await _request(.action, name, args)
    }

    /// Run a action on Convex and return the generic ``ConvexValue``
    ///
    /// - Parameters:
    ///   - name: The name of the action function.
    ///   - args: A variadic list of ``Encodable``.
    ///
    /// - Returns: ``ConvexValue``
    ///
    /// - Throws:
    ///   - ``ConvexError``
    ///   - ``DecodingError.dataCorrupted`` if values requested from the payload are corrupted, or if the given data is not valid JSON.
    ///   - An error if any value throws an error during decoding.
    @discardableResult
    func action(_ name: String, _ args: any Encodable...) async throws -> ConvexValue {
        try await _request(.action, name, args)
    }

    private func _request<T: Decodable>(_ udfType: UDFType, _ name: String, _ args: [any Encodable]) async throws -> T {
        let url = URL(string: "api/\(udfType.path)", relativeTo: address)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("swift-convex-\(packageVersion)", forHTTPHeaderField: "Convex-Client")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let auth {
            request.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        }

        let queryBody = QueryBody(path: name, args: args, debug: debug)
        request.httpBody = try encoder.encode(queryBody)

        let (data, httpResponse) = try await URLSession.shared.httpData(for: request)
        if !httpResponse.success, httpResponse.statusCode != statusCodeUdfFailed {
            throw ConvexError.udfFailed(String(decoding: data, as: UTF8.self))
        }
        let response = try decoder.decode(ConvexResponse<T>.self, from: data)

        if debug {
            for line in response.logLines {
                log(udfType: .query, path: name, message: line)
            }
        }

        switch response.status {
        case .success:
            return response.value
        case .error:
            throw ConvexError.developerError(response.errorMessage ?? "~Unknown error, check Convex logs~")
        }
    }

    private func log(udfType: UDFType, path: String, message: String) {
        Self.logger.info("[CONVEX \(udfType)(\(path))] \(message)")
    }
}
