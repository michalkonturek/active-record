import Foundation
import SwiftData
import Testing

@testable import ActiveRecord

@Suite("Validatable")
struct ValidatableTests {

    // MARK: - Helpers

    private func jsonData(_ dict: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: dict)
    }

    // MARK: - validate()

    @Test @MainActor
    func validateDoesNotThrowForValidModel() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let item = Item(uid: 1, name: "Widget", price: 10)
        context.insert(item)

        #expect(throws: Never.self) {
            try item.validate()
        }
    }

    @Test @MainActor
    func validateThrowsForInvalidModel() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let item = Item(uid: 1, name: "", price: -1)
        context.insert(item)

        #expect(throws: ValidationError.self) {
            try item.validate()
        }
    }

    // MARK: - ValidationError

    @Test
    func validationErrorSingleFailure() {
        let error = ValidationError(field: "name", message: "can't be empty")

        #expect(error.failures.count == 1)
        #expect(error.failures[0].field == "name")
        #expect(error.failures[0].message == "can't be empty")
        #expect(error.errorDescription?.contains("name: can't be empty") == true)
    }

    @Test
    func validationErrorMultipleFailures() {
        let error = ValidationError(failures: [
            .init(field: "name", message: "can't be empty"),
            .init(field: "price", message: "must be non-negative"),
        ])

        #expect(error.failures.count == 2)
        #expect(error.errorDescription?.contains("name: can't be empty") == true)
        #expect(
            error.errorDescription?.contains("price: must be non-negative")
                == true)
    }

    // MARK: - isValid

    @Test @MainActor
    func isValidReturnsTrueForValidModel() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let item = Item(uid: 1, name: "Widget", price: 10)
        context.insert(item)

        #expect(item.isValid == true)
    }

    @Test @MainActor
    func isValidReturnsFalseForInvalidModel() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let item = Item(uid: 1, name: "", price: 10)
        context.insert(item)

        #expect(item.isValid == false)
    }

    // MARK: - Auto-validate in createOrUpdate

    @Test @MainActor
    func createOrUpdatePassesWithValidData() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let data = try jsonData(["uid": 1, "name": "Widget", "price": 10])
        let item = try Item.createOrUpdate(from: data, in: context)

        #expect(item.name == "Widget")
        #expect(try Item.count(in: context) == 1)
    }

    @Test @MainActor
    func createOrUpdateThrowsAndRemovesInvalidModel() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let data = try jsonData(["uid": 1, "name": "", "price": -1])

        #expect(throws: ValidationError.self) {
            try Item.createOrUpdate(from: data, in: context)
        }
        #expect(try Item.count(in: context) == 0)
    }

    @Test @MainActor
    func nonValidatableModelIsUnaffected() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let data = try jsonData(["uid": 1, "name": "SE"])
        let course = try Course.createOrUpdate(from: data, in: context)

        #expect(course.name == "SE")
    }

    // MARK: - Auto-validate in firstOrCreate

    @Test @MainActor
    func firstOrCreatePassesWithValidNewModel() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let item = try Item.firstOrCreate(
            where: #Predicate { $0.uid == 1 },
            in: context
        ) {
            Item(uid: 1, name: "Widget", price: 10)
        }

        #expect(item.name == "Widget")
        #expect(try Item.count(in: context) == 1)
    }

    @Test @MainActor
    func firstOrCreateThrowsForInvalidNewModel() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        #expect(throws: ValidationError.self) {
            try Item.firstOrCreate(
                where: #Predicate { $0.uid == 1 },
                in: context
            ) {
                Item(uid: 1, name: "", price: 10)
            }
        }
        #expect(try Item.count(in: context) == 0)
    }

    @Test @MainActor
    func firstOrCreateDoesNotValidateExistingModel() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        // Insert an invalid item directly (bypassing validation)
        let invalid = Item(uid: 1, name: "", price: -1)
        context.insert(invalid)
        try context.save()

        // firstOrCreate finds existing — should NOT validate
        let result = try Item.firstOrCreate(
            where: #Predicate { $0.uid == 1 },
            in: context
        ) {
            Item(uid: 1, name: "Should not be used", price: 10)
        }

        #expect(result.name == "")
        #expect(try Item.count(in: context) == 1)
    }
}
