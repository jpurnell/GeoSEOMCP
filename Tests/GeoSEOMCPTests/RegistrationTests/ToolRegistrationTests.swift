import Testing
import Foundation
@testable import GeoSEOMCP
@testable import SwiftMCPServer

@Suite("Tool Registration")
struct ToolRegistrationTests {

    @Test("allToolHandlers returns expected count")
    func testToolCount() {
        let handlers = allToolHandlers()
        #expect(handlers.count == 2, "Expected 2 utility tools, got \(handlers.count)")
    }

    @Test("All tool names are unique")
    func testUniqueNames() {
        let handlers = allToolHandlers()
        let names = handlers.map { $0.tool.name }
        let uniqueNames = Set(names)
        #expect(names.count == uniqueNames.count, "Duplicate tool names found: \(names)")
    }

    @Test("Expected utility tool names are registered")
    func testExpectedNames() {
        let map = toolHandlersByName()
        #expect(map["count_syllables"] != nil, "count_syllables not registered")
        #expect(map["calculate_pronoun_density"] != nil, "calculate_pronoun_density not registered")
    }
}
