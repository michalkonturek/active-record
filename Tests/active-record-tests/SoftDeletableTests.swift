import Foundation
import SwiftData
import Testing

@testable import ActiveRecord

@Suite("SoftDeletable", .serialized)
struct SoftDeletableTests {

    @MainActor
    private func setup() throws -> (ModelContainer, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Post.self, configurations: config)
        let context = container.mainContext
        return (container, context)
    }

    @MainActor
    private func insertPosts(in context: ModelContext) throws -> (Post, Post, Post) {
        let p1 = Post(uid: 1, title: "First")
        let p2 = Post(uid: 2, title: "Second")
        let p3 = Post(uid: 3, title: "Third")
        context.insert(p1)
        context.insert(p2)
        context.insert(p3)
        try context.save()
        return (p1, p2, p3)
    }

    // MARK: - softDelete()

    @Test @MainActor
    func softDeleteSetsDeletedAt() throws {
        let (container, context) = try setup()
        let (p1, _, _) = try insertPosts(in: context)

        p1.softDelete()

        #expect(p1.deletedAt != nil)
        _ = container
    }

    @Test @MainActor
    func softDeleteKeepsRecordInContext() throws {
        let (container, context) = try setup()
        let (p1, _, _) = try insertPosts(in: context)

        p1.softDelete()

        let all = try Post.allWithTrashed(in: context)
        #expect(all.count == 3)
        _ = container
    }

    @Test @MainActor
    func softDeleteOverwritesExistingDeletedAt() throws {
        let (container, context) = try setup()
        let (p1, _, _) = try insertPosts(in: context)

        let pastDate = Date.distantPast
        p1.deletedAt = pastDate
        p1.softDelete()

        #expect(p1.deletedAt! > pastDate)
        _ = container
    }

    // MARK: - restore()

    @Test @MainActor
    func restoreClearsDeletedAt() throws {
        let (container, context) = try setup()
        let (p1, _, _) = try insertPosts(in: context)

        p1.softDelete()
        p1.restore()

        #expect(p1.deletedAt == nil)
        _ = container
    }

    @Test @MainActor
    func restoreOnNonDeletedIsNoOp() throws {
        let (container, context) = try setup()
        let (p1, _, _) = try insertPosts(in: context)

        p1.restore()

        #expect(p1.deletedAt == nil)
        _ = container
    }

    // MARK: - Auto-exclusion: all()

    @Test @MainActor
    func allExcludesSoftDeleted() throws {
        let (container, context) = try setup()
        let (p1, _, _) = try insertPosts(in: context)

        p1.softDelete()
        try context.save()

        let results = try Post.all(in: context)
        #expect(results.count == 2)
        #expect(!results.contains { $0.uid == 1 })
        _ = container
    }

    // MARK: - Auto-exclusion: first()

    @Test @MainActor
    func firstSkipsSoftDeleted() throws {
        let (container, context) = try setup()
        let (p1, p2, p3) = try insertPosts(in: context)

        p1.softDelete()
        p2.softDelete()
        p3.softDelete()
        try context.save()

        let result = try Post.first(in: context)
        #expect(result == nil)
        _ = container
    }

    // MARK: - Auto-exclusion: count()

    @Test @MainActor
    func countExcludesSoftDeleted() throws {
        let (container, context) = try setup()
        let (p1, _, _) = try insertPosts(in: context)

        p1.softDelete()
        try context.save()

        #expect(try Post.count(in: context) == 2)
        _ = container
    }

    // MARK: - Auto-exclusion: exists()

    @Test @MainActor
    func existsReturnsFalseWhenAllSoftDeleted() throws {
        let (container, context) = try setup()
        let (p1, p2, p3) = try insertPosts(in: context)

        p1.softDelete()
        p2.softDelete()
        p3.softDelete()
        try context.save()

        #expect(try Post.exists(in: context) == false)
        _ = container
    }

    // MARK: - Explicit predicate does NOT auto-filter

    @Test @MainActor
    func allWithExplicitPredicateIncludesSoftDeleted() throws {
        let (container, context) = try setup()
        let (p1, _, _) = try insertPosts(in: context)

        p1.softDelete()
        try context.save()

        let results = try Post.all(where: #Predicate { $0.uid >= 1 }, in: context)
        #expect(results.count == 3)
        _ = container
    }

    // MARK: - deleteAll soft-deletes

    @Test @MainActor
    func deleteAllSoftDeletesInsteadOfRemoving() throws {
        let (container, context) = try setup()
        let _ = try insertPosts(in: context)

        try Post.deleteAll(in: context)

        let trashed = try Post.allWithTrashed(in: context)
        #expect(trashed.count == 3)
        #expect(trashed.allSatisfy { $0.deletedAt != nil })
        _ = container
    }

    // MARK: - destroyAll

    @Test @MainActor
    func destroyAllPermanentlyRemoves() throws {
        let (container, context) = try setup()
        let (p1, _, _) = try insertPosts(in: context)

        p1.softDelete()
        try context.save()

        try Post.destroyAll(in: context)
        try context.save()

        #expect(try Post.allWithTrashed(in: context).count == 0)
        _ = container
    }

    // MARK: - withTrashed

    @Test @MainActor
    func allWithTrashedReturnsAll() throws {
        let (container, context) = try setup()
        let (p1, _, _) = try insertPosts(in: context)

        p1.softDelete()
        try context.save()

        #expect(try Post.allWithTrashed(in: context).count == 3)
        _ = container
    }

    @Test @MainActor
    func countWithTrashedCountsAll() throws {
        let (container, context) = try setup()
        let (p1, _, _) = try insertPosts(in: context)

        p1.softDelete()
        try context.save()

        #expect(try Post.countWithTrashed(in: context) == 3)
        _ = container
    }

    @Test @MainActor
    func existsWithTrashedIncludesSoftDeleted() throws {
        let (container, context) = try setup()
        let (p1, p2, p3) = try insertPosts(in: context)

        p1.softDelete()
        p2.softDelete()
        p3.softDelete()
        try context.save()

        #expect(try Post.existsWithTrashed(in: context) == true)
        _ = container
    }

    // MARK: - onlyTrashed

    @Test @MainActor
    func allOnlyTrashedReturnsOnlySoftDeleted() throws {
        let (container, context) = try setup()
        let (p1, _, _) = try insertPosts(in: context)

        p1.softDelete()
        try context.save()

        let results = try Post.allOnlyTrashed(in: context)
        #expect(results.count == 1)
        #expect(results[0].uid == 1)
        _ = container
    }

    @Test @MainActor
    func countOnlyTrashedCountsOnlySoftDeleted() throws {
        let (container, context) = try setup()
        let (p1, _, _) = try insertPosts(in: context)

        p1.softDelete()
        try context.save()

        #expect(try Post.countOnlyTrashed(in: context) == 1)
        _ = container
    }
}
