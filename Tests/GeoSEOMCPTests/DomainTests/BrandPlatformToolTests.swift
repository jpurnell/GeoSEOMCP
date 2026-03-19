import Testing
import Foundation
@testable import GeoSEOMCP
@testable import SwiftMCPServer

// MARK: - calculate_brand_authority_score Tool Tests

@Suite("calculate_brand_authority_score Tool")
struct BrandAuthorityScoreToolTests {

    let tool = CalculateBrandAuthorityScoreTool()

    @Test("Known scores produce correct weighted result")
    func testWeightedScore() async throws {
        // 80*0.25 + 60*0.25 + 100*0.20 + 50*0.15 + 40*0.15 = 20+15+20+7.5+6 = 68.5
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"youtube_score": 80, "reddit_score": 60, "wikipedia_score": 100, "linkedin_score": 50, "other_platforms_score": 40}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("68.5"))
    }

    @Test("All zeros produce zero")
    func testAllZeros() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"youtube_score": 0, "reddit_score": 0, "wikipedia_score": 0, "linkedin_score": 0, "other_platforms_score": 0}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("0.0"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - score_platform_presence Tool Tests

@Suite("score_platform_presence Tool")
struct ScorePlatformPresenceToolTests {

    let tool = ScorePlatformPresenceTool()

    @Test("Present with high engagement scores well")
    func testHighEngagement() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"platform": "youtube", "has_presence": true, "follower_count": 50000, "engagement_rate": 5.0, "post_frequency": "weekly"}
        """))
        #expect(!result.isError)
        #expect(result.text.lowercased().contains("youtube"))
    }

    @Test("No presence scores zero")
    func testNoPresence() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"platform": "reddit", "has_presence": false}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("0") || result.text.lowercased().contains("no presence"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - generate_platform_search_urls Tool Tests

@Suite("generate_platform_search_urls Tool")
struct GeneratePlatformSearchUrlsToolTests {

    let tool = GeneratePlatformSearchUrlsTool()

    @Test("Brand name produces platform URLs")
    func testBrandUrls() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"brand_name": "Acme Corp"}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("youtube") || result.text.contains("YouTube"))
        #expect(result.text.contains("reddit") || result.text.contains("Reddit"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - score_platform_readiness Tool Tests

@Suite("score_platform_readiness Tool")
struct ScorePlatformReadinessToolTests {

    let tool = ScorePlatformReadinessTool()

    @Test("Full checklist produces high score")
    func testFullChecklist() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"platform": "google_aio", "checklist_items": [true, true, true, true, true, true, true, true, true, true]}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("100") || result.text.contains("10/10"))
    }

    @Test("Empty checklist scores zero")
    func testEmptyChecklist() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"platform": "chatgpt", "checklist_items": [false, false, false, false, false]}
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
