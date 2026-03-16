import Foundation
import SwiftData

@testable import ActiveRecord

@Model
final class Module: Queryable, Upsertable {
    static var primaryKeyPath: KeyPath<Module, Int> { \.uid }
    static var primaryCodingKey: String { "uid" }

    var uid: Int
    var name: String

    init(uid: Int, name: String) {
        self.uid = uid
        self.name = name
    }

    enum CodingKeys: String, CodingKey {
        case uid, name
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(Int.self, forKey: .uid)
        name = try container.decode(String.self, forKey: .name)
    }
}
