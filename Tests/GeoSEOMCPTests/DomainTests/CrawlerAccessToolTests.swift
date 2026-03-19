import Testing
import Foundation
@testable import GeoSEOMCP
@testable import SwiftMCPServer

// MARK: - Robots.txt Parsing Tests

@Suite("Robots.txt Parsing")
struct RobotsTxtParsingTests {

    @Test("Golden path: parse standard robots.txt")
    func testStandardRobotsTxt() {
        let content = """
        User-agent: GPTBot
        Disallow: /private/

        User-agent: *
        Allow: /
        """
        let rules = parseRobotsTxt(content)
        #expect(rules["GPTBot"] != nil)
        #expect(rules["*"] != nil)
    }

    @Test("Empty robots.txt returns empty rules")
    func testEmptyContent() {
        let rules = parseRobotsTxt("")
        #expect(rules.isEmpty)
    }

    @Test("Comments and blank lines are ignored")
    func testCommentsIgnored() {
        let content = """
        # This is a comment
        User-agent: GPTBot
        # Another comment
        Disallow: /admin/

        """
        let rules = parseRobotsTxt(content)
        #expect(rules["GPTBot"] != nil)
        #expect(rules.count == 1)
    }

    @Test("Multiple user-agents with different rules")
    func testMultipleAgents() {
        let content = """
        User-agent: GPTBot
        Disallow: /

        User-agent: ClaudeBot
        Allow: /

        User-agent: *
        Disallow: /private/
        """
        let rules = parseRobotsTxt(content)
        #expect(rules.count == 3)
    }
}

// MARK: - AI Crawler Access Analysis Tests

@Suite("AI Crawler Access Analysis")
struct AICrawlerAccessTests {

    @Test("Fully open robots.txt allows all crawlers")
    func testFullyOpen() {
        let rules = parseRobotsTxt("""
        User-agent: *
        Allow: /
        """)
        let access = analyzeAICrawlerAccess(rules: rules)
        let allowed = access.filter { $0.status == .allowed }
        #expect(allowed.count == 14, "Expected all 14 crawlers allowed, got \(allowed.count)")
    }

    @Test("Blocking GPTBot reduces tier 1 access")
    func testBlockGPTBot() {
        let rules = parseRobotsTxt("""
        User-agent: GPTBot
        Disallow: /

        User-agent: *
        Allow: /
        """)
        let access = analyzeAICrawlerAccess(rules: rules)
        let gptBot = access.first { $0.crawlerName == "GPTBot" }
        #expect(gptBot?.status == .blocked)
    }

    @Test("Blanket disallow blocks crawlers without specific rules")
    func testBlanketDisallow() {
        let rules = parseRobotsTxt("""
        User-agent: *
        Disallow: /
        """)
        let access = analyzeAICrawlerAccess(rules: rules)
        let blocked = access.filter { $0.status == .blocked }
        #expect(blocked.count == 14, "Expected all crawlers blocked by blanket disallow")
    }

    @Test("Specific allow overrides blanket disallow")
    func testSpecificAllowOverride() {
        let rules = parseRobotsTxt("""
        User-agent: ClaudeBot
        Allow: /

        User-agent: *
        Disallow: /
        """)
        let access = analyzeAICrawlerAccess(rules: rules)
        let claudeBot = access.first { $0.crawlerName == "ClaudeBot" }
        #expect(claudeBot?.status == .allowed)
    }

    @Test("Empty robots.txt allows all crawlers")
    func testEmptyRobotsTxt() {
        let rules = parseRobotsTxt("")
        let access = analyzeAICrawlerAccess(rules: rules)
        let allowed = access.filter { $0.status == .allowed }
        #expect(allowed.count == 14)
    }
}

// MARK: - AI Visibility Score Tests

@Suite("AI Visibility Score")
struct AIVisibilityScoreTests {

    @Test("All allowed yields score near 100")
    func testAllAllowed() {
        let rules = parseRobotsTxt("User-agent: *\nAllow: /")
        let access = analyzeAICrawlerAccess(rules: rules)
        let score = calculateAIVisibilityScore(access: access, hasLlmsTxt: false, hasAiTxt: false)
        #expect(score >= 85, "Expected high score for all allowed, got \(score)")
    }

    @Test("All blocked yields low score")
    func testAllBlocked() {
        let rules = parseRobotsTxt("User-agent: *\nDisallow: /")
        let access = analyzeAICrawlerAccess(rules: rules)
        let score = calculateAIVisibilityScore(access: access, hasLlmsTxt: false, hasAiTxt: false)
        #expect(score < 20, "Expected low score for all blocked, got \(score)")
    }

    @Test("llms.txt and ai.txt bonus increases score")
    func testAIFilesBonus() {
        let rules = parseRobotsTxt("User-agent: *\nAllow: /")
        let access = analyzeAICrawlerAccess(rules: rules)
        let withoutFiles = calculateAIVisibilityScore(access: access, hasLlmsTxt: false, hasAiTxt: false)
        let withFiles = calculateAIVisibilityScore(access: access, hasLlmsTxt: true, hasAiTxt: true)
        #expect(withFiles > withoutFiles, "AI files should increase visibility score")
    }
}

// MARK: - parse_robots_txt Tool Tests

@Suite("parse_robots_txt Tool")
struct ParseRobotsTxtToolTests {

    let tool = ParseRobotsTxtTool()

    @Test("Golden path: valid robots.txt content")
    func testValidContent() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"content": "User-agent: *\\nAllow: /"}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("User-agent"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - analyze_ai_crawler_access Tool Tests

@Suite("analyze_ai_crawler_access Tool")
struct AnalyzeAICrawlerAccessToolTests {

    let tool = AnalyzeAICrawlerAccessTool()

    @Test("Golden path: robots.txt with mixed rules")
    func testMixedRules() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"robots_txt": "User-agent: GPTBot\\nDisallow: /\\n\\nUser-agent: *\\nAllow: /"}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("GPTBot"))
        #expect(result.text.contains("blocked") || result.text.contains("Blocked") || result.text.contains("BLOCKED"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - calculate_ai_visibility_score Tool Tests

@Suite("calculate_ai_visibility_score Tool")
struct CalculateAIVisibilityScoreToolTests {

    let tool = CalculateAIVisibilityScoreTool()

    @Test("Golden path: open robots.txt with AI files")
    func testOpenWithFiles() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"robots_txt": "User-agent: *\\nAllow: /", "has_llms_txt": true, "has_ai_txt": true}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("Score") || result.text.contains("score"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}
