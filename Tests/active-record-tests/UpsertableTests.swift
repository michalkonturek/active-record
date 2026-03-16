import Foundation
import SwiftData
import Testing

@testable import ActiveRecord

@Suite("Upsertable")
struct UpsertableTests {

    // MARK: - Helpers

    private func jsonData(_ dict: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: dict)
    }

    private func jsonArrayData(_ array: [[String: Any]]) throws -> Data {
        try JSONSerialization.data(withJSONObject: array)
    }

    // MARK: - Create Path

    @Test @MainActor
    func createOrUpdateInsertsNewObject() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let data = try jsonData([
            "uid": 1,
            "firstName": "Alice",
            "lastName": "Smith",
            "age": 20,
        ])

        let student = try Student.createOrUpdate(from: data, in: context)
        #expect(student.uid == 1)
        #expect(student.firstName == "Alice")
        #expect(student.lastName == "Smith")
        #expect(student.age == 20)
        #expect(try Student.count(in: context) == 1)
    }

    // MARK: - Update Path

    @Test @MainActor
    func createOrUpdateUpdatesExistingObject() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        try context.save()

        let data = try jsonData([
            "uid": 1,
            "firstName": "Alice",
            "lastName": "Johnson",
            "age": 21,
        ])

        let student = try Student.createOrUpdate(from: data, in: context)
        #expect(student.lastName == "Johnson")
        #expect(student.age == 21)
        #expect(try Student.count(in: context) == 1)
    }

    // MARK: - Batch Upsert

    @Test @MainActor
    func batchUpsertCreatesMultipleObjects() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let data = try jsonArrayData([
            ["uid": 1, "firstName": "Alice", "lastName": "Smith", "age": 20],
            ["uid": 2, "firstName": "Bob", "lastName": "Jones", "age": 22],
        ])

        let results = try Student.createOrUpdate(fromArray: data, in: context)
        #expect(results.count == 2)
        #expect(try Student.count(in: context) == 2)
    }

    @Test @MainActor
    func batchUpsertMixOfNewAndExisting() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        context.insert(Student(uid: 1, firstName: "Alice", lastName: "Smith", age: 20))
        try context.save()

        let data = try jsonArrayData([
            ["uid": 1, "firstName": "Alice", "lastName": "Updated", "age": 21],
            ["uid": 2, "firstName": "Bob", "lastName": "Jones", "age": 22],
        ])

        let results = try Student.createOrUpdate(fromArray: data, in: context)
        #expect(results.count == 2)
        #expect(try Student.count(in: context) == 2)
        #expect(results[0].lastName == "Updated")
        #expect(results[1].firstName == "Bob")
    }

    @Test @MainActor
    func batchUpsertWithDuplicateKeysLastWins() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let data = try jsonArrayData([
            ["uid": 1, "firstName": "Alice", "lastName": "First", "age": 20],
            ["uid": 1, "firstName": "Alice", "lastName": "Last", "age": 25],
        ])

        let results = try Student.createOrUpdate(fromArray: data, in: context)
        #expect(results.count == 2)
        #expect(try Student.count(in: context) == 1)

        let student = try Student.first(in: context)
        #expect(student?.lastName == "Last")
        #expect(student?.age == 25)
    }

    @Test @MainActor
    func batchUpsertEmptyArrayReturnsEmpty() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let data = try jsonArrayData([])
        let results = try Student.createOrUpdate(fromArray: data, in: context)
        #expect(results.isEmpty)
    }

    // MARK: - Dictionary-Based Upsert

    @Test @MainActor
    func createOrUpdateFromDictionary() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let student = try Student.createOrUpdate(
            from: [
                "uid": 1,
                "firstName": "Alice",
                "lastName": "Smith",
                "age": 20,
            ], in: context)

        #expect(student.uid == 1)
        #expect(student.firstName == "Alice")
    }

    // MARK: - Error Cases

    @Test @MainActor
    func missingPrimaryKeyThrowsError() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let data = try jsonData([
            "firstName": "Alice",
            "lastName": "Smith",
            "age": 20,
        ])

        #expect(throws: ActiveRecordError.self) {
            try Student.createOrUpdate(from: data, in: context)
        }
    }

    @Test @MainActor
    func decodingFailureThrowsError() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let data = try jsonData([
            "uid": 1,
            "firstName": "Alice",
                // missing required fields
        ])

        #expect(throws: (any Error).self) {
            try Student.createOrUpdate(from: data, in: context)
        }
    }

    // MARK: - Does Not Auto-Save

    @Test @MainActor
    func upsertDoesNotAutoSave() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let data = try jsonData([
            "uid": 1,
            "firstName": "Alice",
            "lastName": "Smith",
            "age": 20,
        ])

        _ = try Student.createOrUpdate(from: data, in: context)
        #expect(context.hasChanges)
    }

    // MARK: - Works With Different Model Types

    @Test @MainActor
    func upsertWorksWithCourseModel() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let data = try jsonData(["uid": 1, "name": "Software Engineering"])
        let course = try Course.createOrUpdate(from: data, in: context)
        #expect(course.name == "Software Engineering")
    }

    @Test @MainActor
    func upsertWorksWithModuleModel() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let data = try jsonData(["uid": 1, "name": "Module 1"])
        let module = try Module.createOrUpdate(from: data, in: context)
        #expect(module.name == "Module 1")
    }
}
