import Foundation
import SwiftData

@testable import ActiveRecord

@Model
final class Item: Queryable, Upsertable, Validatable {
    static var primaryKeyPath: KeyPath<Item, Int> { \.uid }
    static var primaryCodingKey: String { "uid" }

    var uid: Int
    var name: String
    var price: Int

    init(uid: Int, name: String, price: Int) {
        self.uid = uid
        self.name = name
        self.price = price
    }

    enum CodingKeys: String, CodingKey {
        case uid, name, price
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(Int.self, forKey: .uid)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decode(Int.self, forKey: .price)
    }

    func validate() throws {
        var failures: [ValidationError.FieldError] = []
        if name.isEmpty {
            failures.append(.init(field: "name", message: "can't be empty"))
        }
        if price < 0 {
            failures.append(.init(field: "price", message: "must be non-negative"))
        }
        if !failures.isEmpty {
            throw ValidationError(failures: failures)
        }
    }
}
