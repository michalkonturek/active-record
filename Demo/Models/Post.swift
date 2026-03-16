import ActiveRecord
import Foundation
import SwiftData

@Model
final class Post: SoftDeletable {
    var uid: Int
    var title: String
    var deletedAt: Date?

    init(uid: Int, title: String, deletedAt: Date? = nil) {
        self.uid = uid
        self.title = title
        self.deletedAt = deletedAt
    }
}
