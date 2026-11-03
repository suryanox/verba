import Foundation

protocol TextInserter: Sendable {
    func insert(_ text: String) async throws
}
