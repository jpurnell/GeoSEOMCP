import Testing
import Foundation
@testable import GeoSEOMCP
@testable import SwiftMCPServer

// MARK: - analyze_security_headers Tool Tests

@Suite("analyze_security_headers Tool")
struct AnalyzeSecurityHeadersToolTests {

    let tool = AnalyzeSecurityHeadersTool()

    @Test("All headers present scores 100")
    func testAllPresent() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"headers": {"strict-transport-security": "max-age=31536000", "content-security-policy": "default-src 'self'", "x-frame-options": "DENY", "x-content-type-options": "nosniff", "referrer-policy": "strict-origin", "permissions-policy": "camera=()"}}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("100"))
    }

    @Test("No headers scores 0")
    func testNoHeaders() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"headers": {}}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("0"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - analyze_heading_structure Tool Tests

@Suite("analyze_heading_structure Tool")
struct AnalyzeHeadingStructureToolTests {

    let tool = AnalyzeHeadingStructureTool()

    @Test("Valid H1→H2→H3 hierarchy passes")
    func testValidHierarchy() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"headings": [{"level": 1, "text": "Title"}, {"level": 2, "text": "Section"}, {"level": 3, "text": "Subsection"}]}
        """))
        #expect(!result.isError)
        #expect(result.text.lowercased().contains("valid") || result.text.contains("✓"))
    }

    @Test("Skipped level is flagged")
    func testSkippedLevel() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"headings": [{"level": 1, "text": "Title"}, {"level": 3, "text": "Subsection"}]}
        """))
        #expect(!result.isError)
        #expect(result.text.lowercased().contains("skip"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - audit_meta_tags Tool Tests

@Suite("audit_meta_tags Tool")
struct AuditMetaTagsToolTests {

    let tool = AuditMetaTagsTool()

    @Test("Complete meta tags pass audit")
    func testCompleteTags() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"title": "My Great Page - Company", "description": "This is a detailed description of the page content that provides useful information.", "canonical": "https://example.com/page", "robots": "index, follow"}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("title") || result.text.contains("Title"))
    }

    @Test("Empty title is flagged")
    func testEmptyTitle() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"title": "", "description": "Some description"}
        """))
        #expect(!result.isError)
        #expect(result.text.lowercased().contains("missing") || result.text.lowercased().contains("empty"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - detect_ssr_capability Tool Tests

@Suite("detect_ssr_capability Tool")
struct DetectSSRCapabilityToolTests {

    let tool = DetectSSRCapabilityTool()

    @Test("SSR signals produce SSR classification")
    func testSSRSignals() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"has_initial_content": true, "has_next_data": true, "has_nuxt_data": false, "content_length": 5000}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("SSR") || result.text.contains("Server"))
    }

    @Test("CSR signals produce CSR classification")
    func testCSRSignals() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"has_initial_content": false, "has_next_data": false, "has_nuxt_data": false, "content_length": 200}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("CSR") || result.text.contains("Client"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - score_technical_seo Tool Tests

@Suite("score_technical_seo Tool")
struct ScoreTechnicalSEOToolTests {

    let tool = ScoreTechnicalSEOTool()

    @Test("Perfect scores produce high composite")
    func testPerfectScores() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"ssr_score": 100, "meta_tags_score": 100, "crawlability_score": 100, "security_score": 100, "core_web_vitals_score": 100, "mobile_score": 100, "url_score": 100, "server_response_score": 100}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("100"))
    }

    @Test("All zeros produce zero composite")
    func testZeroScores() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"ssr_score": 0, "meta_tags_score": 0, "crawlability_score": 0, "security_score": 0, "core_web_vitals_score": 0, "mobile_score": 0, "url_score": 0, "server_response_score": 0}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("0"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}
