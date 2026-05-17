import Testing
import Foundation
@testable import GeoSEOMCP
@testable import SwiftMCPServer

@Suite("Tool Registration")
struct ToolRegistrationTests {

    @Test("allToolHandlers returns expected count")
    func testToolCount() {
        let handlers = allToolHandlers()
        #expect(handlers.count == 29, "Expected 29 tools, got \(handlers.count)")
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
        #expect(map.keys.contains("count_syllables"), "count_syllables not registered")
        #expect(map.keys.contains("calculate_pronoun_density"), "calculate_pronoun_density not registered")
        // Citability tools
        #expect(map.keys.contains("score_passage_citability"), "score_passage_citability not registered")
        #expect(map.keys.contains("analyze_page_citability"), "analyze_page_citability not registered")
        // Crawler access tools
        #expect(map.keys.contains("parse_robots_txt"), "parse_robots_txt not registered")
        #expect(map.keys.contains("analyze_ai_crawler_access"), "analyze_ai_crawler_access not registered")
        #expect(map.keys.contains("calculate_ai_visibility_score"), "calculate_ai_visibility_score not registered")
        // llms.txt tools
        #expect(map.keys.contains("validate_llmstxt"), "validate_llmstxt not registered")
        #expect(map.keys.contains("categorize_urls_for_llmstxt"), "categorize_urls_for_llmstxt not registered")
    }
}
