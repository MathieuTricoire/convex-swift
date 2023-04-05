import Foundation

extension URLSession {
    func httpData(
        for request: URLRequest,
        delegate _: URLSessionTaskDelegate? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await data(for: request)
        // swiftlint:disable force_cast
        // Ok to force here because according to the doc urlResponse will always be an `HTTPURLResponse` if the request is an http request.
        let httpUrlResponse = response as! HTTPURLResponse
        // swiftlint:enable force_cast
        return (data, httpUrlResponse)
    }
}
