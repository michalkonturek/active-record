import Foundation
import SwiftData
import Testing

@testable import active_record

@Suite("Timestampable")
struct TimestampableTests {

    // MARK: - touch()

    @Test @MainActor
    func touchUpdatesOnlyUpdatedAt() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let pastDate = Date.distantPast
        let article = Article(uid: 1, title: "Test", createdAt: pastDate, updatedAt: pastDate)
        context.insert(article)
        try context.save()

        article.touch()

        #expect(article.createdAt == pastDate)
        #expect(article.updatedAt > pastDate)
    }

    // MARK: - stampCreated()

    @Test @MainActor
    func stampCreatedSetsBothTimestamps() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let pastDate = Date.distantPast
        let article = Article(uid: 1, title: "Test", createdAt: pastDate, updatedAt: pastDate)
        context.insert(article)

        article.stampCreated()

        #expect(article.createdAt > pastDate)
        #expect(article.updatedAt > pastDate)
        #expect(article.createdAt == article.updatedAt)
    }

    // MARK: - Auto-stamp in createOrUpdate

    @Test @MainActor
    func createOrUpdateAutoStampsTimestampableModel() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let data = try JSONSerialization.data(
            withJSONObject: ["uid": 1, "title": "Auto-stamped"])

        let article = try Article.createOrUpdate(from: data, in: context)

        let now = Date()
        #expect(now.timeIntervalSince(article.createdAt) < 2)
        #expect(now.timeIntervalSince(article.updatedAt) < 2)
    }

    // MARK: - Auto-stamp in firstOrCreate

    @Test @MainActor
    func firstOrCreateAutoStampsNewTimestampableModel() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let pastDate = Date.distantPast
        let article = try Article.firstOrCreate(
            where: #Predicate { $0.uid == 1 },
            in: context
        ) {
            Article(uid: 1, title: "New", createdAt: pastDate, updatedAt: pastDate)
        }

        #expect(article.createdAt > pastDate)
        #expect(article.updatedAt > pastDate)
    }

    @Test @MainActor
    func firstOrCreateDoesNotStampExistingModel() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let pastDate = Date.distantPast
        let existing = Article(uid: 1, title: "Existing", createdAt: pastDate, updatedAt: pastDate)
        context.insert(existing)
        try context.save()

        let result = try Article.firstOrCreate(
            where: #Predicate { $0.uid == 1 },
            in: context
        ) {
            Article(uid: 1, title: "Should Not Be Used")
        }

        #expect(result.createdAt == pastDate)
        #expect(result.updatedAt == pastDate)
    }
}
