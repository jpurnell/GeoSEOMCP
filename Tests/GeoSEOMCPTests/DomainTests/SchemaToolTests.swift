import Testing
import Foundation
@testable import GeoSEOMCP
@testable import SwiftMCPServer

// MARK: - validate_json_ld Tool Tests

@Suite("validate_json_ld Tool")
struct ValidateJsonLdToolTests {

    let tool = ValidateJsonLdTool()

    @Test("Valid Organization JSON-LD passes")
    func testValidOrg() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"json_ld": "{\\"@context\\":\\"https://schema.org\\",\\"@type\\":\\"Organization\\",\\"name\\":\\"Acme Corp\\",\\"url\\":\\"https://acme.com\\"}"}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("Organization"))
    }

    @Test("Missing @context is flagged")
    func testMissingContext() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"json_ld": "{\\"@type\\":\\"Organization\\",\\"name\\":\\"Test\\"}"}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("@context") || result.text.contains("context"))
    }

    @Test("Missing @type is flagged")
    func testMissingType() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"json_ld": "{\\"@context\\":\\"https://schema.org\\",\\"name\\":\\"Test\\"}"}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("@type") || result.text.contains("type"))
    }

    @Test("Invalid JSON is handled")
    func testInvalidJson() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"json_ld": "not valid json at all"}
        """))
        #expect(!result.isError)
        #expect(result.text.lowercased().contains("invalid") || result.text.lowercased().contains("error"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - audit_sameas_coverage Tool Tests

@Suite("audit_sameas_coverage Tool")
struct AuditSameAsCoverageToolTests {

    let tool = AuditSameAsCoverageTool()

    @Test("Full coverage scores high")
    func testFullCoverage() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"sameas_urls": ["https://en.wikipedia.org/wiki/Acme", "https://www.wikidata.org/wiki/Q123", "https://www.linkedin.com/company/acme", "https://www.youtube.com/@acme", "https://twitter.com/acme", "https://facebook.com/acme", "https://github.com/acme", "https://www.crunchbase.com/organization/acme"]}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("15") || result.text.contains("100"))
    }

    @Test("No sameAs URLs scores zero")
    func testNoCoverage() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"sameas_urls": []}
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

// MARK: - score_schema_completeness Tool Tests

@Suite("score_schema_completeness Tool")
struct ScoreSchemaCompletenessToolTests {

    let tool = ScoreSchemaCompletenessTool()

    @Test("Multiple schema types score higher")
    func testMultipleTypes() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"schema_types": ["Organization", "WebSite", "Article", "BreadcrumbList", "FAQPage"]}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("5"))
    }

    @Test("Empty schema types scores zero")
    func testNoTypes() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"schema_types": []}
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

// MARK: - generate_schema_template Tool Tests

@Suite("generate_schema_template Tool")
struct GenerateSchemaTemplateToolTests {

    let tool = GenerateSchemaTemplateTool()

    @Test("Organization template produces valid JSON")
    func testOrganizationTemplate() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"business_type": "organization"}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("@context"))
        #expect(result.text.contains("Organization"))
    }

    @Test("Article template produces valid JSON")
    func testArticleTemplate() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"business_type": "article"}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("Article"))
    }

    @Test("Unknown type handled gracefully")
    func testUnknownType() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"business_type": "unknown_type"}
        """))
        #expect(!result.isError)
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}
