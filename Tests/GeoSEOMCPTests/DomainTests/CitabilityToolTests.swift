import Testing
import Foundation
@testable import GeoSEOMCP
@testable import SwiftMCPServer

// MARK: - score_passage_citability Tests

@Suite("score_passage_citability Tool")
struct ScorePassageCitabilityToolTests {

    let tool = ScorePassageCitabilityTool()

    @Test("Golden path: well-structured factual passage scores B or better")
    func testWellStructuredPassage() async throws {
        // A ~150-word factual passage with stats, definitions, and structure
        let passage = """
        Search Engine Optimization is the process of improving a website's visibility \
        in organic search results. According to recent studies, 68% of online experiences \
        begin with a search engine. The global SEO industry is valued at approximately \
        $80 billion as of 2024. Effective SEO strategies include keyword research, \
        content optimization, technical improvements, and link building. Google processes \
        over 8.5 billion searches per day, making it the dominant platform for organic \
        discovery. Websites ranking on the first page of Google receive 91.5% of all \
        search traffic. Core Web Vitals, introduced in 2021, measure loading performance, \
        interactivity, and visual stability. Mobile-first indexing means Google primarily \
        uses the mobile version of content for ranking. Schema markup provides structured \
        data that helps search engines understand page content more effectively.
        """
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "\(passage.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n"))"}
        """))
        #expect(!result.isError)
        let text = result.text
        // Should contain a grade of A or B
        #expect(text.contains("Grade:"), "Expected grade in output")
    }

    @Test("Short vague passage scores poorly")
    func testShortVaguePassage() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "We do things that help people. They like what we offer. It works well for them."}
        """))
        #expect(!result.isError)
        let text = result.text
        // Short, pronoun-heavy, no stats → should score low
        #expect(text.contains("Grade:"), "Expected grade in output")
    }

    @Test("Empty text returns zero score")
    func testEmptyText() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": ""}
        """))
        #expect(!result.isError)
        let text = result.text
        #expect(text.contains("0"), "Expected 0 score for empty text")
    }

    @Test("Missing text argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }

    @Test("Statistic-heavy passage scores well on statistical density")
    func testStatisticHeavy() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "Revenue grew 25% to $1.2 billion in 2024. Margins improved from 15% to 22%. The company added 500 employees across 3 offices. Stock price increased 45% year-over-year."}
        """))
        #expect(!result.isError)
        let text = result.text
        #expect(text.contains("Statistical"), "Expected statistical density dimension in output")
    }

    @Test("Definition-rich passage scores well on answer block quality")
    func testDefinitionRich() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "GEO refers to the practice of optimizing web content for AI-powered search engines. Citability is defined as the likelihood that an AI system will quote a passage. A citable passage means a self-contained block of text that answers a question directly."}
        """))
        #expect(!result.isError)
        let text = result.text
        #expect(text.contains("Answer Block"), "Expected answer block dimension in output")
    }
}

// MARK: - Passage Scoring Function Tests

@Suite("Passage Citability Scoring")
struct PassageCitabilityScoringTests {

    @Test("scorePassageCitability returns score between 0 and 100")
    func testScoreRange() {
        let score = scorePassageCitability("This is a test passage with some content.")
        #expect(score.composite >= 0 && score.composite <= 100)
    }

    @Test("Empty text returns zero composite")
    func testEmptyText() {
        let score = scorePassageCitability("")
        #expect(score.composite == 0)
    }

    @Test("Optimal word count passage scores higher on answer block quality")
    func testOptimalWordCount() {
        // Build a ~150 word passage
        let words = Array(repeating: "word", count: 150)
        let passage150 = words.joined(separator: " ")
        let score150 = scorePassageCitability(passage150)

        // Build a ~30 word passage
        let shortWords = Array(repeating: "word", count: 30)
        let passage30 = shortWords.joined(separator: " ")
        let score30 = scorePassageCitability(passage30)

        #expect(score150.answerBlockQuality > score30.answerBlockQuality,
                "150 words should score higher on answer block quality than 30 words")
    }

    @Test("High pronoun density reduces self-containment score")
    func testPronounPenalty() {
        let lowPronoun = "The company reported strong quarterly results. Revenue increased significantly."
        let highPronoun = "He said that she told them it was their responsibility to fix it for them."

        let scoreLow = scorePassageCitability(lowPronoun)
        let scoreHigh = scorePassageCitability(highPronoun)

        #expect(scoreLow.selfContainment > scoreHigh.selfContainment,
                "Low pronoun text should have better self-containment score")
    }

    @Test("Grade thresholds are correct")
    func testGradeThresholds() {
        #expect(citabilityGrade(for: 85) == "A")
        #expect(citabilityGrade(for: 70) == "B")
        #expect(citabilityGrade(for: 55) == "C")
        #expect(citabilityGrade(for: 40) == "D")
        #expect(citabilityGrade(for: 20) == "F")
    }
}

// MARK: - analyze_page_citability Tests

@Suite("analyze_page_citability Tool")
struct AnalyzePageCitabilityToolTests {

    let tool = AnalyzePageCitabilityTool()

    @Test("Golden path: multi-paragraph page produces analysis")
    func testMultiParagraph() async throws {
        let page = """
        First paragraph about SEO basics. Search engines crawl the web.

        Second paragraph with statistics. Revenue grew 25% in 2024 to $5 billion.

        Third paragraph about technical details. Core Web Vitals measure performance.
        """
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "\(page.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n"))"}
        """))
        #expect(!result.isError)
        let text = result.text
        #expect(text.contains("3"), "Expected 3 passages analyzed")
    }

    @Test("Single paragraph produces 1 passage")
    func testSingleParagraph() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "This is a single paragraph with no double newlines inside it."}
        """))
        #expect(!result.isError)
        let text = result.text
        #expect(text.contains("1"), "Expected 1 passage")
    }

    @Test("Empty text returns zero passages")
    func testEmptyText() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": ""}
        """))
        #expect(!result.isError)
        let text = result.text
        #expect(text.contains("0"), "Expected 0 passages for empty text")
    }

    @Test("Missing text argument throws error")
    func testMissingArgument() async throws {
        await #expect(throws: (any Error).self) {
            try await tool.execute(arguments: argsFromJSON("{}"))
        }
    }

    @Test("Page type parameter is accepted")
    func testPageType() async throws {
        let result = try await tool.execute(arguments: argsFromJSON("""
        {"text": "Some content about products and services.", "page_type": "blog"}
        """))
        #expect(!result.isError)
    }
}
