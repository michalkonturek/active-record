import Foundation

public enum ActiveRecordError: Error, LocalizedError {
    case missingPrimaryKey(type: String, key: String)
    case decodingFailed(type: String, underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .missingPrimaryKey(let type, let key):
            "Primary key '\(key)' not found in JSON for type '\(type)'"
        case .decodingFailed(let type, let underlying):
            "Failed to decode '\(type)': \(underlying.localizedDescription)"
        }
    }
}
