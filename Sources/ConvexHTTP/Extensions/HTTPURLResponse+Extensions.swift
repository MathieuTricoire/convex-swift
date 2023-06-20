import Foundation

extension HTTPURLResponse {
    var success: Bool {
        statusCode >= 200 && statusCode < 300
    }

    var clientError: Bool {
        statusCode >= 400 && statusCode < 500
    }
}
