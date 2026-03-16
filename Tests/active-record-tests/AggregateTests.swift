import Foundation
import SwiftData
import Testing

@testable import ActiveRecord

@Suite("Aggregates")
struct AggregateTests {

    // MARK: - sum()

    @Test @MainActor
    func sumAllAges() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 25))
        context.insert(Student(uid: 3, firstName: "Charlie", lastName: "Brown", age: 30))
        try context.save()

        let result = try Student.sum(for: \.age, in: context)
        #expect(result == 75)
    }

    @Test @MainActor
    func sumWithPredicate() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 25))
        context.insert(Student(uid: 3, firstName: "Charlie", lastName: "Brown", age: 30))
        try context.save()

        let result = try Student.sum(for: \.age, where: #Predicate { $0.age > 20 }, in: context)
        #expect(result == 55)
    }

    @Test @MainActor
    func sumReturnsZeroWhenEmpty() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let result = try Student.sum(for: \.age, in: context)
        #expect(result == 0)
    }

    // MARK: - average()

    @Test @MainActor
    func averageAllAges() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 25))
        try context.save()

        let result = try Student.average(for: \.age, in: context)
        #expect(result == 22.5)
    }

    @Test @MainActor
    func averageReturnsNonTruncatedResult() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 1))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 2))
        try context.save()

        let result = try Student.average(for: \.age, in: context)
        #expect(result == 1.5)
    }

    @Test @MainActor
    func averageReturnsNilWhenEmpty() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let result = try Student.average(for: \.age, in: context)
        #expect(result == nil)
    }

    // MARK: - pluck()

    @Test @MainActor
    func pluckAllFirstNames() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 22))
        context.insert(Student(uid: 3, firstName: "Charlie", lastName: "Brown", age: 19))
        try context.save()

        let result = try Student.pluck(\.firstName, in: context)
        #expect(result.count == 3)
        #expect(result.contains("Alice"))
        #expect(result.contains("Bob"))
        #expect(result.contains("Charlie"))
    }

    @Test @MainActor
    func pluckWithPredicate() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 22))
        context.insert(Student(uid: 3, firstName: "Charlie", lastName: "Brown", age: 19))
        try context.save()

        let result = try Student.pluck(
            \.firstName, where: #Predicate { $0.age > 20 }, in: context)
        #expect(result.count == 1)
        #expect(result.contains("Bob"))
    }

    @Test @MainActor
    func pluckReturnsEmptyArrayWhenEmpty() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let result = try Student.pluck(\.firstName, in: context)
        #expect(result.isEmpty)
    }
}
