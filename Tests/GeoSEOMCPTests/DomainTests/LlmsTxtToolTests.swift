import Testing
import Foundation
@testable import GeoSEOMCP
@testable import SwiftMCPServer

// MARK: - llms.txt Validation Tests

@Suite("llms.txt Validation")
struct LlmsTxtValidationTests {

    @Test("Valid llms.txt with all required sections passes")
    func testValidLlmsTxt() {
        let content = """
        # Acme Corporation

        > Acme Corporation provides innovative solutions for modern businesses.

        ## Products
        - [Product A](/products/a): Our flagship product
        - [Product B](/products/b): Enterprise solution

        ## Resources
        - [Blog](/blog): Company blog
        - [Docs](/docs): Documentation
        """
        let result = validateLlmsTxt(content)
        #expect(result.isValid)
        #expect(result.hasTitle)
        #expect(result.hasDescription)
        #expect(result.hasSections)
    }

    @Test("Missing H1 title fails validation")
    func testMissingTitle() {
        let content = """
        > Just a description without a title.

        ## Products
        - [Product A](/products/a): Description
        """
        let result = validateLlmsTxt(content)
        #expect(!result.hasTitle)
    }

    @Test("Missing blockquote description is flagged")
    func testMissingDescription() {
        let content = """
        # Acme Corporation

        ## Products
        - [Product A](/products/a): Description
        """
        let result = validateLlmsTxt(content)
        #expect(result.hasTitle)
        #expect(!result.hasDescription)
    }

    @Test("Empty content fails")
    func testEmptyContent() {
        let result = validateLlmsTxt("")
        #expect(!result.isValid)
    }

    @Test("Link count is accurate")
    func testLinkCount() {
        let content = """
        # Title

        > Description

        ## Section
        - [Link 1](/a): First
        - [Link 2](/b): Second
        - [Link 3](/c): Third
        """
        let result = validateLlmsTxt(content)
        #expect(result.linkCount == 3)
    }
}

// MARK: - URL Categorization Tests

@Suite("URL Categorization for llms.txt")
struct URLCategorizationTests {

    @Test("Common URL patterns are categorized correctly")
    func testCommonPatterns() {
        let categories = categorizeUrlsForLlmsTxt([
            "/pricing",
            "/blog/my-post",
            "/about",
            "/docs/getting-started",
            "/products/widget",
            "/contact",
        ])
        #expect(categories["/pricing"] != nil)
        #expect(categories["/blog/my-post"] != nil)
        #expect(categories["/about"] != nil)
    }

    @Test("Empty URL list returns empty result")
    func testEmptyList() {
        let categories = categorizeUrlsForLlmsTxt([])
        #expect(categories.isEmpty)
    }
}

// MARK: - validate_llmstxt Tool Tests

@Suite("validate_llmstxt Tool")
struct ValidateLlmsTxtToolTests {

    let tool = ValidateLlmsTxtTool()

    @Test("Golden path: valid llms.txt content")
    func testValidContent() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"content": "# Title\\n\\n> Description\\n\\n## Section\\n- [Link](/url): Desc"}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("Title"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}

// MARK: - categorize_urls_for_llmstxt Tool Tests

@Suite("categorize_urls_for_llmstxt Tool")
struct CategorizeUrlsToolTests {

    let tool = CategorizeUrlsForLlmsTxtTool()

    @Test("Golden path: categorize URL list")
    func testCategorizeUrls() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"urls": ["/pricing", "/blog/post", "/about", "/docs/guide"]}
        """))
        #expect(!result.isError)
        #expect(result.text.contains("pricing") || result.text.contains("Pricing"))
    }

    @Test("Missing argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }
}
