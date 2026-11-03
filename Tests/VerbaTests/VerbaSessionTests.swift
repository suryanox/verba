import Foundation
import Testing
@testable import Verba

@Test("A session follows the recording-to-review lifecycle")
@MainActor
func sessionLifecycle() {
    let session = VerbaSession()
    let startedAt = Date(timeIntervalSince1970: 123)

    session.startListening(at: startedAt)
    #expect(session.state == .listening(startedAt: startedAt))

    session.stopListening()
    #expect(session.state == .transcribing)

    session.showTranscript("Hello world")
    #expect(session.state == .reviewing(originalText: nil, transcript: "Hello world"))

    session.beginInsertion()
    #expect(session.state == .inserting)

    session.finish()
    #expect(session.state == .idle)
}

@Test("Invalid transitions do not change the session state")
@MainActor
func invalidTransitionsAreIgnored() {
    let session = VerbaSession()

    session.stopListening()
    session.showTranscript("Ignored")
    session.beginInsertion()

    #expect(session.state == .idle)
}
