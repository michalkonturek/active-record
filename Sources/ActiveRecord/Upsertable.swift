import Foundation
import SwiftData

public protocol Upsertable: PersistentModel, Decodable {
    associatedtype PrimaryKey: Equatable
    static var primaryKeyPath: KeyPath<Self, PrimaryKey> { get }
    static var primaryCodingKey: String { get }
}

extension Upsertable {

    // MARK: - Single Upsert (from Data)

    @discardableResult
    public static func createOrUpdate(
        from data: Data,
        using decoder: JSONDecoder = JSONDecoder(),
        in context: ModelContext
    ) throws -> Self {
        let keyValue = try extractPrimaryKey(from: data)

        let decoded: Self
        do {
            decoded = try decoder.decode(Self.self, from: data)
        } catch {
            throw ActiveRecordError.decodingFailed(
                type: String(describing: Self.self),
                underlying: error
            )
        }

        if let existing = try findExisting(key: keyValue, in: context) {
            context.delete(existing)
        }

        context.insert(decoded)
        if let timestampable = decoded as? any Timestampable {
            timestampable.stampCreated()
        }
        if let validatable = decoded as? any Validatable {
            do {
                try validatable.validate()
            } catch {
                context.delete(decoded)
                throw error
            }
        }
        return decoded
    }

    // MARK: - Batch Upsert (from Data)

    @discardableResult
    public static func createOrUpdate(
        fromArray data: Data,
        using decoder: JSONDecoder = JSONDecoder(),
        in context: ModelContext
    ) throws -> [Self] {
        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
            return []
        }
        var results: [Self] = []
        for element in jsonArray {
            let elementData = try JSONSerialization.data(withJSONObject: element)
            let result = try createOrUpdate(from: elementData, using: decoder, in: context)
            results.append(result)
        }
        return results
    }

    // MARK: - Dictionary-Based Upsert

    @discardableResult
    public static func createOrUpdate(
        from dictionary: [String: Any],
        in context: ModelContext
    ) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try createOrUpdate(from: data, in: context)
    }

    // MARK: - Private Helpers

    private static func extractPrimaryKey(from data: Data) throws -> PrimaryKey {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ActiveRecordError.missingPrimaryKey(
                type: String(describing: Self.self),
                key: primaryCodingKey
            )
        }
        guard let rawValue = json[primaryCodingKey] else {
            throw ActiveRecordError.missingPrimaryKey(
                type: String(describing: Self.self),
                key: primaryCodingKey
            )
        }
        guard let value = rawValue as? PrimaryKey else {
            throw ActiveRecordError.missingPrimaryKey(
                type: String(describing: Self.self),
                key: primaryCodingKey
            )
        }
        return value
    }

    private static func findExisting(key: PrimaryKey, in context: ModelContext) throws -> Self? {
        let descriptor = FetchDescriptor<Self>()
        let all = try context.fetch(descriptor)
        return all.first { $0[keyPath: primaryKeyPath] == key }
    }
}
