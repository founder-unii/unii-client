import Foundation

public struct UniiApiError: LocalizedError, Sendable {
    public let statusCode: Int
    public let message: String
    public let details: String?

    public init(statusCode: Int, message: String, details: String? = nil) {
        self.statusCode = statusCode
        self.message = message
        self.details = details
    }

    public var errorDescription: String? {
        if let details = details, !details.isEmpty {
            return "Unii API Error (\(statusCode)): \(message) - \(details)"
        }
        return "Unii API Error (\(statusCode)): \(message)"
    }
}
