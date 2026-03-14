import Foundation
import SwiftData

public protocol Timestampable: PersistentModel {
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
}

extension Timestampable {

    public func touch() {
        updatedAt = Date()
    }

    public func stampCreated() {
        let now = Date()
        createdAt = now
        updatedAt = now
    }
}
