import Foundation
import SwiftData

public protocol SoftDeletable: Queryable {
    var deletedAt: Date? { get set }
}

extension SoftDeletable {

    // MARK: - Instance Methods

    public func softDelete() {
        deletedAt = Date()
    }

    public func restore() {
        deletedAt = nil
    }

    // MARK: - Query Overrides (auto-exclude soft-deleted)

    public static func all(in context: ModelContext) throws -> [Self] {
        try all(where: #Predicate { $0.deletedAt == nil }, in: context)
    }

    public static func first(in context: ModelContext) throws -> Self? {
        try all(
            where: #Predicate { $0.deletedAt == nil },
            sort: [], limit: 1, offset: nil, in: context
        ).first
    }

    public static func count(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<Self>(predicate: #Predicate { $0.deletedAt == nil })
        return try context.fetchCount(descriptor)
    }

    public static func exists(in context: ModelContext) throws -> Bool {
        try count(in: context) > 0
    }

    // MARK: - Delete Overrides (soft-delete by default)

    public static func deleteAll(in context: ModelContext) throws {
        let objects = try allWithTrashed(in: context).filter { $0.deletedAt == nil }
        for object in objects {
            object.softDelete()
        }
    }

    public static func deleteAll(
        where predicate: Predicate<Self>,
        in context: ModelContext
    ) throws {
        let objects = try all(where: predicate, in: context)
        for object in objects {
            object.softDelete()
        }
    }

    // MARK: - Permanent Deletion

    public static func destroyAll(in context: ModelContext) throws {
        let objects = try allWithTrashed(in: context)
        for object in objects {
            context.delete(object)
        }
    }

    public static func destroyAll(
        where predicate: Predicate<Self>,
        in context: ModelContext
    ) throws {
        let objects = try all(where: predicate, in: context)
        for object in objects {
            context.delete(object)
        }
    }

    // MARK: - With Trashed (includes soft-deleted)

    public static func allWithTrashed(in context: ModelContext) throws -> [Self] {
        let descriptor = FetchDescriptor<Self>()
        return try context.fetch(descriptor)
    }

    public static func countWithTrashed(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<Self>()
        return try context.fetchCount(descriptor)
    }

    public static func existsWithTrashed(in context: ModelContext) throws -> Bool {
        try countWithTrashed(in: context) > 0
    }

    // MARK: - Only Trashed (only soft-deleted)

    public static func allOnlyTrashed(in context: ModelContext) throws -> [Self] {
        try all(where: #Predicate { $0.deletedAt != nil }, in: context)
    }

    public static func countOnlyTrashed(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<Self>(predicate: #Predicate { $0.deletedAt != nil })
        return try context.fetchCount(descriptor)
    }
}
