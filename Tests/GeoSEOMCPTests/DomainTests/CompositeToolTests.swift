import Testing
import Foundation
@testable import GeoSEOMCP
@testable import SwiftMCPServer

// MARK: - calculate_geo_composite_score Tool Tests

@Suite("calculate_geo_composite_score Tool")
struct GEOCompositeScoreToolTests {

    let tool = CalculateGEOCompositeScoreTool()

    @Test("All 100s produce composite 100")
    func testPerfect() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"citability_score": 100, "brand_authority_score": 100, "eeat_score": 100, "technical_score": 100, "schema_score": 100, "platform_score": 100}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("100"))
    }

    @Test("All 0s produce composite 0")
    func testZero() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"citability_score": 0, "brand_authority_score": 0, "eeat_score": 0, "technical_score": 0, "schema_score": 0, "platform_score": 0}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("0.0"))
    }

    @Test("Known mix produces correct weighted score")
    func testKnownMix() async throws {
        // 80*0.25 + 60*0.20 + 70*0.20 + 90*0.15 + 50*0.10 + 40*0.10
        // = 20 + 12 + 14 + 13.5 + 5 + 4 = 68.5
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"citability_score": 80, "brand_authority_score": 60, "eeat_score": 70, "technical_score": 90, "schema_score": 50, "platform_score": 40}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("68.5"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - classify_audit_findings Tool Tests

@Suite("classify_audit_findings Tool")
struct ClassifyAuditFindingsToolTests {

    let tool = ClassifyAuditFindingsTool()

    @Test("Large gaps classified as critical")
    func testCriticalGap() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"findings": [{"area": "Security Headers", "current_score": 20, "target_score": 80}]}
        """))
        #expect(!result.isError)
        #expect(result.text.lowercased().contains("critical"))
    }

    @Test("Small gaps classified as low priority")
    func testLowGap() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"findings": [{"area": "Meta Tags", "current_score": 90, "target_score": 95}]}
        """))
        #expect(!result.isError)
        #expect(result.text.lowercased().contains("low"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - detect_business_type Tool Tests

@Suite("detect_business_type Tool")
struct DetectBusinessTypeToolTests {

    let tool = DetectBusinessTypeTool()

    @Test("SaaS signals produce SaaS classification")
    func testSaaS() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"signals": ["pricing_page", "signup_cta", "api_docs", "free_trial"]}
        """))
        #expect(!result.isError)
        #expect(result.text.lowercased().contains("saas"))
    }

    @Test("Local business signals produce local classification")
    func testLocal() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"signals": ["physical_address", "google_maps", "phone_number", "opening_hours"]}
        """))
        #expect(!result.isError)
        #expect(result.text.lowercased().contains("local"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}
