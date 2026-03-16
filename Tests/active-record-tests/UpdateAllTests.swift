import Foundation
import SwiftData
import Testing

@testable import ActiveRecord

@Suite("UpdateAll")
struct UpdateAllTests {

    @Test @MainActor
    func updateAllRecords() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 25))
        context.insert(Student(uid: 3, firstName: "Charlie", lastName: "Brown", age: 30))
        try context.save()

        try Student.updateAll(in: context) { $0.age += 1 }

        let students = try Student.all(in: context)
        let ages = students.map(\.age).sorted()
        #expect(ages == [21, 26, 31])
    }

    @Test @MainActor
    func updateAllWithPredicate() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        context.insert(Student(uid: 2, firstName: "Bob", lastName: "Jones", age: 25))
        context.insert(Student(uid: 3, firstName: "Charlie", lastName: "Brown", age: 30))
        try context.save()

        try Student.updateAll(
            where: #Predicate { $0.age >= 25 },
            in: context
        ) { $0.lastName = "Updated" }

        let updated = try Student.all(where: #Predicate { $0.lastName == "Updated" }, in: context)
        #expect(updated.count == 2)

        let unchanged = try Student.first(where: #Predicate { $0.uid == 1 }, in: context)
        #expect(unchanged?.lastName == "Smith")
    }

    @Test @MainActor
    func updateAllOnEmptySetIsNoOp() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        try Student.updateAll(in: context) { $0.age += 1 }
        #expect(try Student.count(in: context) == 0)
    }

    @Test @MainActor
    func updateAllDoesNotAutoSave() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        try context.save()

        try Student.updateAll(in: context) { $0.age = 99 }

        #expect(context.hasChanges)
    }
}
