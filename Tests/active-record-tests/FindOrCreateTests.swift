import Foundation
import SwiftData
import Testing

@testable import active_record

@Suite("FindOrCreate")
struct FindOrCreateTests {

    // MARK: - firstOrCreate

    @Test @MainActor
    func firstOrCreateReturnsExistingRecord() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        try context.save()

        let result = try Student.firstOrCreate(
            where: #Predicate { $0.uid == 1 },
            in: context
        ) {
            Student(uid: 1, firstName: "Should Not", lastName: "Be Used", age: 99)
        }

        #expect(result.firstName == "Alice")
        #expect(try Student.count(in: context) == 1)
    }

    @Test @MainActor
    func firstOrCreateCreatesWhenNotFound() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let result = try Student.firstOrCreate(
            where: #Predicate { $0.uid == 99 },
            in: context
        ) {
            Student(uid: 99, firstName: "New", lastName: "Student", age: 18)
        }

        #expect(result.firstName == "New")
        #expect(result.uid == 99)
        #expect(try Student.count(in: context) == 1)
    }

    @Test @MainActor
    func firstOrCreateDoesNotAutoSave() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        _ = try Student.firstOrCreate(
            where: #Predicate { $0.uid == 1 },
            in: context
        ) {
            Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20)
        }

        #expect(context.hasChanges)
    }

    // MARK: - firstOrInitialize

    @Test @MainActor
    func firstOrInitializeReturnsExistingRecord() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        try context.save()

        let result = try Student.firstOrInitialize(
            where: #Predicate { $0.uid == 1 },
            in: context
        ) {
            Student(uid: 1, firstName: "Should Not", lastName: "Be Used", age: 99)
        }

        #expect(result.firstName == "Alice")
    }

    @Test @MainActor
    func firstOrInitializeDoesNotInsert() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let result = try Student.firstOrInitialize(
            where: #Predicate { $0.uid == 99 },
            in: context
        ) {
            Student(uid: 99, firstName: "New", lastName: "Student", age: 18)
        }

        #expect(result.firstName == "New")
        #expect(try Student.count(in: context) == 0)
    }
}
