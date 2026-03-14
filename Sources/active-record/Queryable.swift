import Foundation
import SwiftData

public protocol Queryable: PersistentModel {}

extension Queryable {

    // MARK: - Fetch All

    public static func all(in context: ModelContext) throws -> [Self] {
        try all(where: nil, sort: [], in: context)
    }

    public static func all(
        where predicate: Predicate<Self>,
        in context: ModelContext
    ) throws -> [Self] {
        try all(where: predicate, sort: [], in: context)
    }

    public static func all(
        where predicate: Predicate<Self>?,
        sort descriptors: SortDescriptor<Self>...,
        in context: ModelContext
    ) throws -> [Self] {
        try all(where: predicate, sort: descriptors, in: context)
    }

    public static func all(
        where predicate: Predicate<Self>?,
        sort descriptors: [SortDescriptor<Self>],
        in context: ModelContext
    ) throws -> [Self] {
        try all(where: predicate, sort: descriptors, limit: nil, offset: nil, in: context)
    }

    public static func all(
        where predicate: Predicate<Self>?,
        sort descriptors: [SortDescriptor<Self>],
        limit: Int?,
        offset: Int?,
        in context: ModelContext
    ) throws -> [Self] {
        var descriptor = FetchDescriptor<Self>(predicate: predicate, sortBy: descriptors)
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        return try context.fetch(descriptor)
    }

    // MARK: - Fetch First

    public static func first(in context: ModelContext) throws -> Self? {
        try all(where: nil, sort: [], limit: 1, offset: nil, in: context).first
    }

    public static func first(
        where predicate: Predicate<Self>,
        in context: ModelContext
    ) throws -> Self? {
        try all(where: predicate, sort: [], limit: 1, offset: nil, in: context).first
    }

    // MARK: - Count

    public static func count(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<Self>()
        return try context.fetchCount(descriptor)
    }

    public static func count(
        where predicate: Predicate<Self>,
        in context: ModelContext
    ) throws -> Int {
        let descriptor = FetchDescriptor<Self>(predicate: predicate)
        return try context.fetchCount(descriptor)
    }

    // MARK: - Exists

    public static func exists(in context: ModelContext) throws -> Bool {
        try count(in: context) > 0
    }

    public static func exists(
        where predicate: Predicate<Self>,
        in context: ModelContext
    ) throws -> Bool {
        try count(where: predicate, in: context) > 0
    }

    // MARK: - Aggregate Finders

    public static func withMaxValue<V: Comparable>(
        for keyPath: KeyPath<Self, V> & Sendable,
        in context: ModelContext
    ) throws -> Self? {
        var descriptor = FetchDescriptor<Self>(
            sortBy: [SortDescriptor(keyPath, order: .reverse)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    public static func withMinValue<V: Comparable>(
        for keyPath: KeyPath<Self, V> & Sendable,
        in context: ModelContext
    ) throws -> Self? {
        var descriptor = FetchDescriptor<Self>(
            sortBy: [SortDescriptor(keyPath, order: .forward)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // MARK: - Delete All

    public static func deleteAll(in context: ModelContext) throws {
        let objects = try all(in: context)
        for object in objects {
            context.delete(object)
        }
    }

    public static func deleteAll(
        where predicate: Predicate<Self>,
        in context: ModelContext
    ) throws {
        let objects = try all(where: predicate, in: context)
        for object in objects {
            context.delete(object)
        }
    }
}
