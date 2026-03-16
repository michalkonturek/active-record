import Foundation
import SwiftData
import Testing

@testable import ActiveRecord

@Suite("Queryable")
struct QueryableTests {

    // MARK: - all()

    @Test @MainActor
    func allReturnsEmptyArrayWhenNoObjects() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let results = try Student.all(in: context)
        #expect(results.isEmpty)
    }

    @Test @MainActor
    func allReturnsSingleObject() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        try context.save()

        let results = try Student.all(in: context)
        #expect(results.count == 1)
        #expect(results[0].firstName == "Alice")
    }

    @Test @MainActor
    func allReturnsMultipleObjects() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 22))
        context.insert(Student(uid: 3, firstName: "Charlie", lastName: "Brown", age: 19))
        try context.save()

        let results = try Student.all(in: context)
        #expect(results.count == 3)
    }

    // MARK: - all(where:)

    @Test @MainActor
    func allWithPredicateFiltersResults() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 22))
        context.insert(Student(uid: 3, firstName: "Charlie", lastName: "Brown", age: 19))
        try context.save()

        let results = try Student.all(where: #Predicate { $0.age > 20 }, in: context)
        #expect(results.count == 1)
        #expect(results[0].firstName == "Bob")
    }

    // MARK: - all(where:sort:)

    @Test @MainActor
    func allWithSortReturnsOrderedResults() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Charlie", lastName: "Brown", age: 19))
        context.insert(Student(uid: 2, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 3, firstName: "Bob", lastName: "Jones", age: 22))
        try context.save()

        let results = try Student.all(
            where: nil,
            sort: SortDescriptor(\.age),
            in: context
        )
        #expect(results.count == 3)
        #expect(results[0].firstName == "Charlie")
        #expect(results[1].firstName == "Alice")
        #expect(results[2].firstName == "Bob")
    }

    @Test @MainActor
    func allWithReverseSortReturnsDescendingResults() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Charlie", lastName: "Brown", age: 19))
        context.insert(Student(uid: 2, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 3, firstName: "Bob", lastName: "Jones", age: 22))
        try context.save()

        let results = try Student.all(
            where: nil,
            sort: SortDescriptor(\.age, order: .reverse),
            in: context
        )
        #expect(results.count == 3)
        #expect(results[0].firstName == "Bob")
        #expect(results[2].firstName == "Charlie")
    }

    // MARK: - all(where:sort:limit:offset:)

    @Test @MainActor
    func allWithLimitReturnsLimitedResults() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 22))
        context.insert(Student(uid: 3, firstName: "Charlie", lastName: "Brown", age: 19))
        try context.save()

        let results = try Student.all(
            where: nil,
            sort: [SortDescriptor(\.age)],
            limit: 2,
            offset: nil,
            in: context
        )
        #expect(results.count == 2)
    }

    @Test @MainActor
    func allWithOffsetSkipsResults() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Charlie", lastName: "Brown", age: 19))
        context.insert(Student(uid: 2, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 3, firstName: "Bob", lastName: "Jones", age: 22))
        try context.save()

        let results = try Student.all(
            where: nil,
            sort: [SortDescriptor(\.age)],
            limit: nil,
            offset: 1,
            in: context
        )
        #expect(results.count == 2)
    }

    // MARK: - first()

    @Test @MainActor
    func firstReturnsNilWhenEmpty() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let result = try Student.first(in: context)
        #expect(result == nil)
    }

    @Test @MainActor
    func firstReturnsObject() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        try context.save()

        let result = try Student.first(in: context)
        #expect(result != nil)
        #expect(result?.firstName == "Alice")
    }

    @Test @MainActor
    func firstWithPredicateReturnsMatchingObject() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 22))
        try context.save()

        let result = try Student.first(where: #Predicate { $0.age > 21 }, in: context)
        #expect(result?.firstName == "Bob")
    }

    @Test @MainActor
    func firstWithPredicateReturnsNilWhenNoMatch() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        try context.save()

        let result = try Student.first(where: #Predicate { $0.age > 30 }, in: context)
        #expect(result == nil)
    }

    // MARK: - count()

    @Test @MainActor
    func countReturnsZeroWhenEmpty() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        #expect(try Student.count(in: context) == 0)
    }

    @Test @MainActor
    func countReturnsCorrectCount() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 22))
        try context.save()

        #expect(try Student.count(in: context) == 2)
    }

    @Test @MainActor
    func countWithPredicateReturnsFilteredCount() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 22))
        context.insert(Student(uid: 3, firstName: "Charlie", lastName: "Brown", age: 19))
        try context.save()

        #expect(try Student.count(where: #Predicate { $0.age >= 20 }, in: context) == 2)
    }

    // MARK: - exists()

    @Test @MainActor
    func existsReturnsFalseWhenEmpty() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        #expect(try Student.exists(in: context) == false)
    }

    @Test @MainActor
    func existsReturnsTrueWhenObjectsExist() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        try context.save()

        #expect(try Student.exists(in: context) == true)
    }

    @Test @MainActor
    func existsWithPredicateReturnsFalseWhenNoMatch() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        try context.save()

        #expect(try Student.exists(where: #Predicate { $0.age > 30 }, in: context) == false)
    }

    @Test @MainActor
    func existsWithPredicateReturnsTrueWhenMatch() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        try context.save()

        #expect(try Student.exists(where: #Predicate { $0.age == 20 }, in: context) == true)
    }

    // MARK: - withMaxValue / withMinValue

    @Test @MainActor
    func withMaxValueReturnsNilWhenEmpty() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let result = try Student.withMaxValue(for: \.age, in: context)
        #expect(result == nil)
    }

    @Test @MainActor
    func withMaxValueReturnsCorrectObject() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 22))
        context.insert(Student(uid: 3, firstName: "Charlie", lastName: "Brown", age: 19))
        try context.save()

        let result = try Student.withMaxValue(for: \.age, in: context)
        #expect(result?.firstName == "Bob")
    }

    @Test @MainActor
    func withMinValueReturnsNilWhenEmpty() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let result = try Student.withMinValue(for: \.age, in: context)
        #expect(result == nil)
    }

    @Test @MainActor
    func withMinValueReturnsCorrectObject() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 22))
        context.insert(Student(uid: 3, firstName: "Charlie", lastName: "Brown", age: 19))
        try context.save()

        let result = try Student.withMinValue(for: \.age, in: context)
        #expect(result?.firstName == "Charlie")
    }

    // MARK: - deleteAll()

    @Test @MainActor
    func deleteAllRemovesAllObjects() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 22))
        try context.save()

        try Student.deleteAll(in: context)
        try context.save()

        #expect(try Student.count(in: context) == 0)
    }

    @Test @MainActor
    func deleteAllIsNoOpWhenEmpty() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        try Student.deleteAll(in: context)
        #expect(try Student.count(in: context) == 0)
    }

    @Test @MainActor
    func deleteAllWithPredicateRemovesOnlyMatching() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 22))
        context.insert(Student(uid: 3, firstName: "Charlie", lastName: "Brown", age: 19))
        try context.save()

        try Student.deleteAll(where: #Predicate { $0.age < 21 }, in: context)
        try context.save()

        let remaining = try Student.all(in: context)
        #expect(remaining.count == 1)
        #expect(remaining[0].firstName == "Bob")
    }
}
