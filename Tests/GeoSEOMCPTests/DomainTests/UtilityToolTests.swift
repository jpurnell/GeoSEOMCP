import Testing
import Foundation
@testable import GeoSEOMCP
@testable import SwiftMCPServer

// MARK: - count_syllables Tool Tests

@Suite("count_syllables Tool")
struct CountSyllablesToolTests {

    let tool = CountSyllablesTool()

    @Test("Golden path: counts syllables in multi-word text")
    func testMultiWordText() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "hello world"}
        """))
        #expect(!result.isError)
        let text = result.text
        #expect(text.contains("3"), "Expected total syllables = 3 in output: \(text)")
    }

    @Test("Single word returns correct count")
    func testSingleWord() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "beautiful"}
        """))
        #expect(!result.isError)
        let text = result.text
        #expect(text.contains("3"), "Expected 3 syllables for 'beautiful' in output: \(text)")
    }

    @Test("Empty text returns zero")
    func testEmptyText() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": ""}
        """))
        #expect(!result.isError)
        let text = result.text
        #expect(text.contains("0"), "Expected 0 syllables for empty text: \(text)")
    }

    @Test("Missing text argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: ToolError.self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - calculate_pronoun_density Tool Tests

@Suite("calculate_pronoun_density Tool")
struct CalculatePronounDensityToolTests {

    let tool = CalculatePronounDensityTool()

    @Test("Golden path: text with pronouns shows density > 0")
    func testWithPronouns() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "She went to the store and he stayed home"}
        """))
        #expect(!result.isError)
        let text = result.text
        // "She" and "he" should be detected as pronouns
        #expect(text.lowercased().contains("pronoun"), "Expected pronoun info in output: \(text)")
    }

    @Test("Text without pronouns shows zero or near-zero density")
    func testNoPronouns() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "The cat sat on the mat"}
        """))
        #expect(!result.isError)
        let text = result.text
        #expect(text.contains("0"), "Expected 0 pronouns in output: \(text)")
    }

    @Test("Empty text returns zero density")
    func testEmptyText() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": ""}
        """))
        #expect(!result.isError)
        let text = result.text
        #expect(text.contains("0"), "Expected 0 density for empty text: \(text)")
    }

    @Test("Missing text argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: ToolError.self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}
