import Foundation
import SwiftData

public protocol Validatable: PersistentModel {
    func validate() throws
}

extension Validatable {

    public var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }
}

public struct ValidationError: Error, LocalizedError, Sendable {

    public let failures: [FieldError]

    public struct FieldError: Sendable {
        public let field: String
        public let message: String

        public init(field: String, message: String) {
            self.field = field
            self.message = message
        }
    }

    public init(failures: [FieldError]) {
        self.failures = failures
    }

    public init(field: String, message: String) {
        self.failures = [FieldError(field: field, message: message)]
    }

    public var errorDescription: String? {
        let descriptions = failures.map { "\($0.field): \($0.message)" }
        return "Validation failed — \(descriptions.joined(separator: "; "))"
    }
}
