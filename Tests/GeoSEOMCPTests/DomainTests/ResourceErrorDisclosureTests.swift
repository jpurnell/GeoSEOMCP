import Testing
import Foundation
import MCP
import GeoSEOMCP
import SwiftMCPServer

// MARK: - What a failed resources/read tells the caller

/// SwiftMCPServer 5.0.0 returns an error's text to the caller only when the error's type
/// conforms to `CallerVisibleError`; anything else becomes a generic sentence and a
/// reference id. `ResourceError.notFound` repeats the URI the caller sent and nothing
/// about the server, so it is written for the caller and must keep reaching them.
@Suite("ResourceError disclosure")
struct ResourceErrorDisclosureTests {

    @Test("notFound is caller-visible and repeats only the caller's URI")
    func notFoundIsCallerVisible() throws {
        let error: any Error = ResourceError.notFound("docs://no-such-guide")
        let visible = try #require(error as? any CallerVisibleError)
        #expect(visible.callerMessage == "Resource not found: docs://no-such-guide")
    }

    @Test("callerMessage is the errorDescription, byte for byte")
    func callerMessageMatchesErrorDescription() throws {
        let error = ResourceError.notFound("template://missing")
        let visible = try #require((error as any Error) as? any CallerVisibleError)
        #expect(error.errorDescription == "Resource not found: template://missing")
        #expect(visible.callerMessage == error.errorDescription)
    }

    @Test("resources/read for an unknown URI answers with the written message, not a reference id")
    func unknownURIReachesCallerThroughTheServerPath() async throws {
        let thrown = await #expect(throws: MCPError.self) {
            try await MCPServer.readResource(from: ResourceProvider(), uri: "docs://no-such-guide")
        }
        #expect(thrown == MCPError.internalError("Resource not found: docs://no-such-guide"))
    }

    @Test("resources/read for a known URI is unaffected")
    func knownURIStillReads() async throws {
        let result = try await MCPServer.readResource(from: ResourceProvider(), uri: "template://robots-txt")
        #expect(result.contents.count == 1)
        #expect(result.contents.first?.uri == "template://robots-txt")
    }
}
