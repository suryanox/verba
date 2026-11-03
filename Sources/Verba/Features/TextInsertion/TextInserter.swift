import Foundation

@MainActor
protocol TextInserter {
    func insert(_ text: String, into target: FocusedTextTarget) throws
}
