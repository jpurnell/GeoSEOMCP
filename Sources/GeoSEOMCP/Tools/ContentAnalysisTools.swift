import Foundation
import SwiftMCPServer

/// Returns all content analysis tools.
public func getContentAnalysisTools() -> [any MCPToolHandler] {
    return [
        CalculateFleschReadabilityTool(),
        AnalyzeContentStatisticsTool(),
        CalculateEEATScoreTool(),
        CheckContentBenchmarksTool(),
    ]
}

// MARK: - calculate_flesch_readability Tool

/// Calculate Flesch readability scores for text.
public struct CalculateFleschReadabilityTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "calculate_flesch_readability",
        description: """
        Calculate Flesch readability scores for text content.

        Computes:
        - Flesch Reading Ease (0-100, higher = easier)
        - Flesch-Kincaid Grade Level (US grade level)
        - Word, sentence, and syllable counts used in calculation
        - Interpretation of the reading ease score

        Ideal range for AI-citable content: 40-60 (college level).
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "text": MCPSchemaProperty(
                    type: "string",
                    description: "The text to analyze for readability"
                ),
            ],
            required: ["text"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("text")
        }

        let text = try args.getString("text")

        guard !text.isEmpty else {
            return .success(text: "Flesch Readability Analysis\n\nNo text provided.")
        }

        let wordCount = countWords(in: text)
        let sentenceCount = countSentences(in: text)
        let syllableCount = countPassageSyllables(text)

        let readingEase = fleschReadingEase(
            totalWords: wordCount, totalSentences: sentenceCount, totalSyllables: syllableCount
        )
        let gradeLevel = fleschKincaidGradeLevel(
            totalWords: wordCount, totalSentences: sentenceCount, totalSyllables: syllableCount
        )

        let interpretation: String
        if readingEase.isNaN {
            interpretation = "Unable to calculate (insufficient text)"
        } else if readingEase >= 90 {
            interpretation = "Very Easy — 5th grade level"
        } else if readingEase >= 80 {
            interpretation = "Easy — 6th grade level"
        } else if readingEase >= 70 {
            interpretation = "Fairly Easy — 7th grade level"
        } else if readingEase >= 60 {
            interpretation = "Standard — 8th-9th grade level"
        } else if readingEase >= 50 {
            interpretation = "Fairly Difficult — 10th-12th grade (ideal for AI citability)"
        } else if readingEase >= 30 {
            interpretation = "Difficult — College level (good for AI citability)"
        } else {
            interpretation = "Very Difficult — Graduate level"
        }

        let output = """
        Flesch Readability Analysis

        Flesch Reading Ease: \(readingEase.isNaN ? "N/A" : String(format: "%.1f", readingEase))
        Flesch-Kincaid Grade Level: \(gradeLevel.isNaN ? "N/A" : String(format: "%.1f", gradeLevel))

        Text Statistics:
          Words: \(wordCount)
          Sentences: \(sentenceCount)
          Syllables: \(syllableCount)
          Avg syllables/word: \(wordCount > 0 ? String(format: "%.2f", Double(syllableCount) / Double(wordCount)) : "N/A")
          Avg words/sentence: \(sentenceCount > 0 ? String(format: "%.1f", Double(wordCount) / Double(sentenceCount)) : "N/A")

        Interpretation: \(interpretation)
        """

        let result = GeoSEOResult(
            tool: "calculate_flesch_readability",
            resultType: .analysis,
            score: nil,
            data: [
                "readingEase": .number(readingEase.isNaN ? 0.0 : readingEase),
                "gradeLevel": .number(gradeLevel.isNaN ? 0.0 : gradeLevel),
                "wordCount": .integer(wordCount),
                "sentenceCount": .integer(sentenceCount),
                "syllableCount": .integer(syllableCount),
                "interpretation": .string(interpretation),
            ]
        )
        return .structured(json: result, text: output)
    }
}

// MARK: - analyze_content_statistics Tool

/// Analyze content statistics: word count, sentences, paragraphs, etc.
public struct AnalyzeContentStatisticsTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "analyze_content_statistics",
        description: """
        Analyze content statistics for a text passage or page.

        Returns comprehensive text metrics:
        - Word count, sentence count, paragraph count
        - Average words per sentence, sentences per paragraph
        - Syllable statistics and readability indicators
        - Statistical element count (numbers, percentages, currencies)
        - Pronoun density and definition pattern detection
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "text": MCPSchemaProperty(
                    type: "string",
                    description: "The text content to analyze"
                ),
            ],
            required: ["text"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("text")
        }

        let text = try args.getString("text")

        guard !text.isEmpty else {
            return .success(text: "Content Statistics\n\nNo text provided.")
        }

        let wordCount = countWords(in: text)
        let sentenceCount = countSentences(in: text)
        let paragraphs = splitParagraphs(text)
        let syllableCount = countPassageSyllables(text)
        let statElements = countStatisticalElements(in: text)
        let density = pronounDensity(in: text)
        let hasDefinitions = containsDefinitionPattern(text)
        let hasLists = containsListStructure(text)

        let output = """
        Content Statistics

        Structure:
          Word Count: \(wordCount)
          Sentence Count: \(sentenceCount)
          Paragraph Count: \(paragraphs.count)
          Avg Words/Sentence: \(sentenceCount > 0 ? String(format: "%.1f", Double(wordCount) / Double(sentenceCount)) : "N/A")
          Avg Sentences/Paragraph: \(paragraphs.count > 0 ? String(format: "%.1f", Double(sentenceCount) / Double(paragraphs.count)) : "N/A")

        Readability:
          Total Syllables: \(syllableCount)
          Avg Syllables/Word: \(wordCount > 0 ? String(format: "%.2f", Double(syllableCount) / Double(wordCount)) : "N/A")

        Content Signals:
          Statistical Elements: \(statElements)
          Pronoun Density: \(String(format: "%.1f", density * 100))%
          Contains Definitions: \(hasDefinitions ? "Yes" : "No")
          Contains List Structure: \(hasLists ? "Yes" : "No")
        """

        let result = GeoSEOResult(
            tool: "analyze_content_statistics",
            resultType: .analysis,
            score: nil,
            data: [
                "wordCount": .integer(wordCount),
                "sentenceCount": .integer(sentenceCount),
                "paragraphCount": .integer(paragraphs.count),
                "syllableCount": .integer(syllableCount),
                "statisticalElements": .integer(statElements),
                "pronounDensity": .number(density),
                "hasDefinitions": .bool(hasDefinitions),
                "hasLists": .bool(hasLists),
            ]
        )
        return .structured(json: result, text: output)
    }
}

// MARK: - calculate_eeat_score Tool

/// Calculate E-E-A-T score from component ratings.
public struct CalculateEEATScoreTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "calculate_eeat_score",
        description: """
        Calculate an E-E-A-T (Experience, Expertise, Authoritativeness, Trustworthiness) score.

        Each component is rated 0-25 (total base score 0-100).
        An optional modifier (-10 to +10) adjusts for additional signals.
        Final score capped at 0-110.

        E-E-A-T signals are critical for GEO because AI systems prioritize \
        authoritative, expert content in their citations.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "experience": MCPSchemaProperty(
                    type: "number",
                    description: "Experience score (0-25): first-hand experience signals"
                ),
                "expertise": MCPSchemaProperty(
                    type: "number",
                    description: "Expertise score (0-25): subject matter expertise signals"
                ),
                "authoritativeness": MCPSchemaProperty(
                    type: "number",
                    description: "Authoritativeness score (0-25): domain authority signals"
                ),
                "trustworthiness": MCPSchemaProperty(
                    type: "number",
                    description: "Trustworthiness score (0-25): trust and credibility signals"
                ),
                "modifier": MCPSchemaProperty(
                    type: "number",
                    description: "Optional modifier (-10 to +10) for additional E-E-A-T signals"
                ),
            ],
            required: ["experience", "expertise", "authoritativeness", "trustworthiness"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("experience")
        }

        let experience = try args.getDouble("experience")
        let expertise = try args.getDouble("expertise")
        let authoritativeness = try args.getDouble("authoritativeness")
        let trustworthiness = try args.getDouble("trustworthiness")
        let modifier = args.getDoubleOptional("modifier") ?? 0.0

        let baseScore = experience + expertise + authoritativeness + trustworthiness
        let finalScore = min(max(baseScore + modifier, 0), 110)

        let grade: String
        if finalScore >= 90 { grade = "Excellent" }
        else if finalScore >= 75 { grade = "Good" }
        else if finalScore >= 50 { grade = "Fair" }
        else if finalScore >= 25 { grade = "Poor" }
        else { grade = "Very Poor" }

        let output = """
        E-E-A-T Score Analysis

        Component Scores (0-25 each):
          Experience:        \(String(format: "%.1f", experience))
          Expertise:         \(String(format: "%.1f", expertise))
          Authoritativeness: \(String(format: "%.1f", authoritativeness))
          Trustworthiness:   \(String(format: "%.1f", trustworthiness))

        Base Score: \(String(format: "%.1f", baseScore)) / 100
        Modifier: \(modifier >= 0 ? "+" : "")\(String(format: "%.1f", modifier))
        Final Score: \(String(format: "%.1f", finalScore)) / 110

        Assessment: \(grade)
        """

        let result = GeoSEOResult(
            tool: "calculate_eeat_score",
            resultType: .scored,
            score: ScorePayload(value: finalScore, maximum: 110, grade: grade),
            data: [
                "experience": .number(experience),
                "expertise": .number(expertise),
                "authoritativeness": .number(authoritativeness),
                "trustworthiness": .number(trustworthiness),
                "modifier": .number(modifier),
                "baseScore": .number(baseScore),
            ]
        )
        return .structured(json: result, text: output)
    }
}

// MARK: - check_content_benchmarks Tool

/// Check content against page-type benchmarks.
public struct CheckContentBenchmarksTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "check_content_benchmarks",
        description: """
        Check text content against page-type-specific benchmarks.

        Compares word count and readability against ideal ranges for:
        homepage, blog, pillar, product, service, about, faq

        Reports whether content meets minimum requirements and falls \
        within ideal ranges for the specified page type.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "text": MCPSchemaProperty(
                    type: "string",
                    description: "The text content to check"
                ),
                "page_type": MCPSchemaProperty(
                    type: "string",
                    description: "Page type: homepage, blog, pillar, product, service, about, faq"
                ),
            ],
            required: ["text", "page_type"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("text")
        }

        let text = try args.getString("text")
        let pageType = try args.getString("page_type")

        let wordCount = countWords(in: text)
        let sentenceCount = countSentences(in: text)
        let syllableCount = countPassageSyllables(text)
        let readingEase = fleschReadingEase(
            totalWords: wordCount, totalSentences: sentenceCount, totalSyllables: syllableCount
        )

        guard let benchmark = ContentBenchmarks.all[pageType] else {
            let validTypes = ContentBenchmarks.all.keys.sorted().joined(separator: ", ")
            return .success(text: """
            Content Benchmark Check

            Unknown page type: \(pageType)
            Valid types: \(validTypes)

            Content Stats:
              Word Count: \(wordCount)
              Flesch Reading Ease: \(readingEase.isNaN ? "N/A" : String(format: "%.1f", readingEase))
            """)
        }

        var issues: [String] = []
        var passes: [String] = []

        // Word count checks
        if wordCount < benchmark.minimumWords {
            issues.append("Word count (\(wordCount)) is below minimum (\(benchmark.minimumWords)) for \(pageType)")
        } else if wordCount >= benchmark.idealRangeMin && wordCount <= benchmark.idealRangeMax {
            passes.append("Word count (\(wordCount)) is in ideal range (\(benchmark.idealRangeMin)-\(benchmark.idealRangeMax))")
        } else if wordCount >= benchmark.minimumWords {
            passes.append("Word count (\(wordCount)) meets minimum (\(benchmark.minimumWords))")
            if wordCount < benchmark.idealRangeMin {
                issues.append("Word count is below ideal range (\(benchmark.idealRangeMin)-\(benchmark.idealRangeMax))")
            }
        }

        // Readability checks
        if !readingEase.isNaN {
            if readingEase >= benchmark.targetFleschMin && readingEase <= benchmark.targetFleschMax {
                passes.append("Readability (\(String(format: "%.1f", readingEase))) is in target range (\(String(format: "%.0f", benchmark.targetFleschMin))-\(String(format: "%.0f", benchmark.targetFleschMax)))")
            } else {
                issues.append("Readability (\(String(format: "%.1f", readingEase))) is outside target range (\(String(format: "%.0f", benchmark.targetFleschMin))-\(String(format: "%.0f", benchmark.targetFleschMax)))")
            }
        }

        let status = issues.isEmpty ? "PASS" : "NEEDS IMPROVEMENT"

        var output = """
        Content Benchmark Check: \(pageType)

        Status: \(status)

        Metrics:
          Word Count: \(wordCount) (min: \(benchmark.minimumWords), ideal: \(benchmark.idealRangeMin)-\(benchmark.idealRangeMax))
          Flesch Reading Ease: \(readingEase.isNaN ? "N/A" : String(format: "%.1f", readingEase)) (target: \(String(format: "%.0f", benchmark.targetFleschMin))-\(String(format: "%.0f", benchmark.targetFleschMax)))
        """

        if !passes.isEmpty {
            output += "\n\nPassing:"
            for pass in passes { output += "\n  ✓ \(pass)" }
        }
        if !issues.isEmpty {
            output += "\n\nIssues:"
            for issue in issues { output += "\n  ✗ \(issue)" }
        }

        let result = GeoSEOResult(
            tool: "check_content_benchmarks",
            resultType: .analysis,
            score: nil,
            data: [
                "pageType": .string(pageType),
                "wordCount": .integer(wordCount),
                "readingEase": .number(readingEase.isNaN ? 0.0 : readingEase),
                "status": .string(status),
                "issues": .array(issues.map { .string($0) }),
                "passes": .array(passes.map { .string($0) }),
            ]
        )
        return .structured(json: result, text: output)
    }
}
