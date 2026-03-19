import Testing
import Foundation
@testable import GeoSEOMCP
@testable import SwiftMCPServer

// MARK: - calculate_flesch_readability Tool Tests

@Suite("calculate_flesch_readability Tool")
struct FleschReadabilityToolTests {

    let tool = CalculateFleschReadabilityTool()

    @Test("Golden path: text produces readability scores")
    func testGoldenPath() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "The cat sat on the mat. The dog ran in the park. Birds fly in the sky."}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("Reading Ease"))
        #expect(result.text.contains("Grade Level"))
    }

    @Test("Empty text handled gracefully")
    func testEmptyText() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": ""}
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

// MARK: - analyze_content_statistics Tool Tests

@Suite("analyze_content_statistics Tool")
struct ContentStatisticsToolTests {

    let tool = AnalyzeContentStatisticsTool()

    @Test("Golden path: produces word count, sentences, paragraphs")
    func testGoldenPath() async throws {
        let text = "First paragraph here.\n\nSecond paragraph with more words. And another sentence."
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "\(text.replacingOccurrences(of: "\n", with: "\\n"))"}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("Word"))
        #expect(result.text.contains("Sentence"))
        #expect(result.text.contains("Paragraph"))
    }

    @Test("Empty text handled gracefully")
    func testEmptyText() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": ""}
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

// MARK: - calculate_eeat_score Tool Tests

@Suite("calculate_eeat_score Tool")
struct EEATScoreToolTests {

    let tool = CalculateEEATScoreTool()

    @Test("Golden path: all 25s produce score of 100")
    func testPerfectScore() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"experience": 25, "expertise": 25, "authoritativeness": 25, "trustworthiness": 25}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("100"))
    }

    @Test("All zeros produce score of 0")
    func testZeroScore() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"experience": 0, "expertise": 0, "authoritativeness": 0, "trustworthiness": 0}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("0"))
    }

    @Test("Modifier adjusts score")
    func testWithModifier() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"experience": 25, "expertise": 25, "authoritativeness": 25, "trustworthiness": 25, "modifier": 10}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("110"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - check_content_benchmarks Tool Tests

@Suite("check_content_benchmarks Tool")
struct ContentBenchmarksToolTests {

    let tool = CheckContentBenchmarksTool()

    @Test("Blog with sufficient words passes")
    func testBlogPass() async throws {
        let words = Array(repeating: "word", count: 1500).joined(separator: " ")
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "\(words)", "page_type": "blog"}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("blog"))
    }

    @Test("Blog with insufficient words flags issue")
    func testBlogFail() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "Short blog post with few words.", "page_type": "blog"}
        """))
        #expect(!result.isError)
        #expect(result.text.lowercased().contains("below") || result.text.lowercased().contains("minimum") || result.text.lowercased().contains("short"))
    }

    @Test("Invalid page type handled gracefully")
    func testInvalidPageType() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "Some content.", "page_type": "nonexistent"}
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
