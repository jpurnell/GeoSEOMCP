import Foundation
import SwiftMCPServer

/// Returns all utility analysis tools.
public func getUtilityTools() -> [any MCPToolHandler] {
    return [
        CountSyllablesTool(),
        CalculatePronounDensityTool(),
    ]
}

// MARK: - count_syllables

/// Count syllables in text for readability analysis.
public struct CountSyllablesTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "count_syllables",
        description: """
        Count syllables in text for readability analysis.

        Counts syllables per word and total for a passage using a vowel-group \
        heuristic with adjustments for silent-e, diphthongs, and hiatus patterns. \
        Uses NLTokenizer for accurate word extraction. Useful for Flesch readability \
        scoring and content analysis.

        Returns total syllables, word count, and average syllables per word.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "text": MCPSchemaProperty(
                    type: "string",
                    description: "The text to count syllables in"
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

        let words = tokenizeWords(text)
        let totalSyllables = words.reduce(0) { $0 + countSyllables(in: $1) }
        let wordCount = words.count
        let avgSyllables = wordCount > 0
            ? Double(totalSyllables) / Double(wordCount)
            : 0.0

        var output = """
        Syllable Analysis

        Total Syllables: \(totalSyllables)
        Word Count: \(wordCount)
        Average Syllables per Word: \(String(format: "%.2f", avgSyllables))
        """

        // Show per-word breakdown for short texts (≤ 20 words)
        if wordCount > 0 && wordCount <= 20 {
            output += "\n\nPer-Word Breakdown:"
            for word in words {
                let syllables = countSyllables(in: word)
                output += "\n  \(word): \(syllables)"
            }
        }

        let result = GeoSEOResult(
            tool: "count_syllables",
            resultType: .analysis,
            data: [
                "totalSyllables": .integer(totalSyllables),
                "wordCount": .integer(wordCount),
                "avgSyllablesPerWord": .number(avgSyllables),
            ]
        )
        return .structured(json: result, text: output)
    }
}

// MARK: - calculate_pronoun_density

/// Calculate pronoun density in text using NLTagger.
public struct CalculatePronounDensityTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "calculate_pronoun_density",
        description: """
        Calculate pronoun density in text using Apple's NaturalLanguage framework.

        Uses NLTagger with lexical class tagging to identify pronouns (I, he, she, \
        they, it, we, etc.). High pronoun density (>15%) reduces AI citability \
        because pronouns create ambiguity when passages are extracted without context.

        Based on research from Princeton, Georgia Tech, and IIT Delhi showing that \
        AI systems preferentially cite self-contained, unambiguous passages.

        Returns pronoun count, word count, density percentage, and citability assessment.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "text": MCPSchemaProperty(
                    type: "string",
                    description: "The text to analyze for pronoun density"
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

        let pronounCount = countPronouns(in: text)
        let wordCount = countWords(in: text)
        let density = pronounDensity(in: text)
        let densityPercent = density * 100

        let assessment: String
        let impact: String
        if densityPercent < 5 {
            assessment = "Low"
            impact = "Excellent for citability — minimal pronoun ambiguity."
        } else if densityPercent < 10 {
            assessment = "Moderate"
            impact = "Acceptable for citability — some pronoun references present."
        } else if densityPercent < 15 {
            assessment = "High"
            impact = "May reduce citability — consider replacing pronouns with specific nouns."
        } else {
            assessment = "Very High"
            impact = "Likely reduces citability — passages with many pronouns are less self-contained when extracted by AI systems."
        }

        let output = """
        Pronoun Density Analysis

        Pronoun Count: \(pronounCount)
        Word Count: \(wordCount)
        Pronoun Density: \(String(format: "%.1f", densityPercent))%

        Assessment: \(assessment)
        Impact: \(impact)
        """

        let result = GeoSEOResult(
            tool: "calculate_pronoun_density",
            resultType: .analysis,
            data: [
                "pronounCount": .integer(pronounCount),
                "wordCount": .integer(wordCount),
                "density": .number(density),
                "assessment": .string(assessment),
            ]
        )
        return .structured(json: result, text: output)
    }
}
