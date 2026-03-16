import Foundation
import SwiftData

@testable import ActiveRecord

@Model
final class Student: Queryable, Upsertable {
    static var primaryKeyPath: KeyPath<Student, Int> { \.uid }
    static var primaryCodingKey: String { "uid" }

    var uid: Int
    var firstName: String
    var lastName: String
    var age: Int
    var course: Course?
    @Relationship var modules: [Module]

    init(
        uid: Int, firstName: String, lastName: String, age: Int, course: Course? = nil,
        modules: [Module] = []
    ) {
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
        self.course = course
        self.modules = modules
    }

    enum CodingKeys: String, CodingKey {
        case uid, firstName, lastName, age
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(Int.self, forKey: .uid)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        age = try container.decode(Int.self, forKey: .age)
        modules = []
    }
}
