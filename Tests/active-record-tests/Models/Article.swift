import Foundation
import SwiftData

@testable import active_record

@Model
final class Article: Queryable, Upsertable, Timestampable {
    static var primaryKeyPath: KeyPath<Article, Int> { \.uid }
    static var primaryCodingKey: String { "uid" }

    var uid: Int
    var title: String
    var createdAt: Date
    var updatedAt: Date

    init(uid: Int, title: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.uid = uid
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case uid, title
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(Int.self, forKey: .uid)
        title = try container.decode(String.self, forKey: .title)
        createdAt = Date()
        updatedAt = Date()
    }
}
