import Foundation
import SwiftData
import active_record

@Model
final class Todo: Queryable, Upsertable {
    static var primaryKeyPath: KeyPath<Todo, Int> { \.uid }
    static var primaryCodingKey: String { "uid" }

    var uid: Int
    var title: String
    var priority: Int
    var completed: Bool

    init(uid: Int, title: String, priority: Int, completed: Bool = false) {
        self.uid = uid
        self.title = title
        self.priority = priority
        self.completed = completed
    }

    enum CodingKeys: String, CodingKey {
        case uid, title, priority, completed
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(Int.self, forKey: .uid)
        title = try container.decode(String.self, forKey: .title)
        priority = try container.decode(Int.self, forKey: .priority)
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false
    }
}
