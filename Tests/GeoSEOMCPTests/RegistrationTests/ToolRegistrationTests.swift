import Testing
import Foundation
@testable import GeoSEOMCP
@testable import SwiftMCPServer

@Suite("Tool Registration")
struct ToolRegistrationTests {

    @Test("allToolHandlers returns expected count")
    func testToolCount() {
        let handlers = allToolHandlers()
        #expect(handlers.count == 7, "Expected 7 tools (2 utility + 2 citability + 3 crawler), got \(handlers.count)")
    }

    @Test("All tool names are unique")
    func testUniqueNames() {
        let handlers = allToolHandlers()
        let names = handlers.map { $0.tool.name }
        let uniqueNames = Set(names)
        #expect(names.count == uniqueNames.count, "Duplicate tool names found: \(names)")
    }

    @Test("Expected tool names are registered")
    func testExpectedNames() {
        let map = toolHandlersByName()
        // Utility tools
        #expect(map["count_syllables"] != nil, "count_syllables not registered")
        #expect(map["calculate_pronoun_density"] != nil, "calculate_pronoun_density not registered")
        // Citability tools
        #expect(map["score_passage_citability"] != nil, "score_passage_citability not registered")
        #expect(map["analyze_page_citability"] != nil, "analyze_page_citability not registered")
        // Crawler access tools
        #expect(map["parse_robots_txt"] != nil, "parse_robots_txt not registered")
        #expect(map["analyze_ai_crawler_access"] != nil, "analyze_ai_crawler_access not registered")
        #expect(map["calculate_ai_visibility_score"] != nil, "calculate_ai_visibility_score not registered")
    }
}
