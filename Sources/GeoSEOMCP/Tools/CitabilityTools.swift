import Foundation
import SwiftMCPServer

/// Returns all citability scoring tools.
public func getCitabilityTools() -> [any MCPToolHandler] {
    return [
        ScorePassageCitabilityTool(),
        AnalyzePageCitabilityTool(),
    ]
}

// MARK: - Citability Scoring Data Types

/// Per-dimension citability scores for a passage.
public struct CitabilityScore: Sendable {
    public let composite: Double
    public let answerBlockQuality: Double
    public let selfContainment: Double
    public let structuralReadability: Double
    public let statisticalDensity: Double
    public let uniquenessSignals: Double
    public let grade: String
    public let wordCount: Int
}

// MARK: - Scoring Functions

/// Score a passage for AI citability across 5 dimensions.
/// Returns a CitabilityScore with composite (0-100) and per-dimension scores.
public func scorePassageCitability(_ text: String) -> CitabilityScore {
    guard !text.isEmpty else {
        return CitabilityScore(
            composite: 0, answerBlockQuality: 0, selfContainment: 0,
            structuralReadability: 0, statisticalDensity: 0, uniquenessSignals: 0,
            grade: "F", wordCount: 0
        )
    }

    let words = tokenizeWords(text)
    let wordCount = words.count
    let sentenceCount = countSentences(in: text)
    let totalSyllables = countPassageSyllables(text)

    // Dimension 1: Answer Block Quality (30%)
    let abq = scoreAnswerBlockQuality(
        wordCount: wordCount, text: text
    )

    // Dimension 2: Self-Containment (25%)
    let sc = scoreSelfContainment(text: text, wordCount: wordCount)

    // Dimension 3: Structural Readability (20%)
    let sr = scoreStructuralReadability(
        totalWords: wordCount, totalSentences: sentenceCount,
        totalSyllables: totalSyllables
    )

    // Dimension 4: Statistical Density (15%)
    let sd = scoreStatisticalDensity(text: text)

    // Dimension 5: Uniqueness Signals (10%)
    let us = scoreUniquenessSignals(text: text, words: words)

    // Composite weighted score
    let composite = abq * GEOWeights.answerBlockQuality
        + sc * GEOWeights.selfContainment
        + sr * GEOWeights.structuralReadability
        + sd * GEOWeights.statisticalDensity
        + us * GEOWeights.uniquenessSignals

    let grade = citabilityGrade(for: composite)

    return CitabilityScore(
        composite: composite,
        answerBlockQuality: abq,
        selfContainment: sc,
        structuralReadability: sr,
        statisticalDensity: sd,
        uniquenessSignals: us,
        grade: grade,
        wordCount: wordCount
    )
}

/// Map a composite score to a letter grade.
public func citabilityGrade(for score: Double) -> String {
    if score >= CitabilityConstants.gradeA { return "A" }
    if score >= CitabilityConstants.gradeB { return "B" }
    if score >= CitabilityConstants.gradeC { return "C" }
    if score >= CitabilityConstants.gradeD { return "D" }
    return "F"
}

// MARK: - Dimension Scoring Functions

private func scoreAnswerBlockQuality(wordCount: Int, text: String) -> Double {
    var score: Double

    switch wordCount {
    case 0..<50:
        score = Double(wordCount) * 2.0
    case 50..<CitabilityConstants.optimalWordCountMin:
        let range = Double(CitabilityConstants.optimalWordCountMin - 50)
        let progress = Double(wordCount - 50) / range
        score = 60.0 + progress * 40.0
    case CitabilityConstants.optimalWordCountMin...CitabilityConstants.optimalWordCountMax:
        score = 100.0
    case (CitabilityConstants.optimalWordCountMax + 1)...250:
        let range = Double(250 - CitabilityConstants.optimalWordCountMax)
        let progress = Double(wordCount - CitabilityConstants.optimalWordCountMax) / range
        score = 100.0 - progress * 30.0
    default:
        score = max(30.0, 70.0 - Double(wordCount - 250) / 5.0)
    }

    if containsDefinitionPattern(text) { score += 15.0 }
    if containsListStructure(text) { score += 10.0 }

    return min(score, 100.0)
}

private func scoreSelfContainment(text: String, wordCount: Int) -> Double {
    var score = 100.0
    let density = pronounDensity(in: text)
    score -= density * 200.0
    if wordCount < 50 { score -= 20.0 }
    return min(max(score, 0.0), 100.0)
}

private func scoreStructuralReadability(totalWords: Int, totalSentences: Int, totalSyllables: Int) -> Double {
    let flesch = fleschReadingEase(
        totalWords: totalWords, totalSentences: totalSentences,
        totalSyllables: totalSyllables
    )

    var score: Double
    if flesch.isNaN {
        score = 40.0
    } else if flesch >= 40 && flesch <= 60 {
        score = 100.0
    } else if (flesch >= 30 && flesch < 40) || (flesch > 60 && flesch <= 70) {
        score = 80.0
    } else if (flesch >= 20 && flesch < 30) || (flesch > 70 && flesch <= 80) {
        score = 60.0
    } else {
        score = 40.0
    }

    if totalSentences >= 3 && totalSentences <= 7 {
        score += 10.0
    }

    return min(score, 100.0)
}

private func scoreStatisticalDensity(text: String) -> Double {
    let elements = countStatisticalElements(in: text)
    return min(Double(elements) * 20.0, 100.0)
}

private func scoreUniquenessSignals(text: String, words: [String]) -> Double {
    var score = 0.0

    // Capitalized words not at sentence start (proxy for proper nouns)
    let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
    var sentenceStarts: Set<String> = []
    for sentence in sentences {
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        if let firstWord = trimmed.split(separator: " ").first {
            sentenceStarts.insert(String(firstWord))
        }
    }

    for word in words {
        if let first = word.first, first.isUppercase, !sentenceStarts.contains(word) {
            score += 15.0
        }
    }

    // Numbers in text
    let numberPattern = #"\b\d+\b"#
    if let regex = try? NSRegularExpression(pattern: numberPattern) {
        let range = NSRange(text.startIndex..., in: text)
        score += Double(regex.numberOfMatches(in: text, range: range)) * 10.0
    }

    // Technical terms (words > 10 chars)
    for word in words where word.count > 10 {
        score += 10.0
    }

    return min(score, 100.0)
}

// MARK: - score_passage_citability Tool

/// Score a single text passage for AI citability across 5 dimensions.
public struct ScorePassageCitabilityTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "score_passage_citability",
        description: """
        Score a text passage for AI citability across 5 dimensions.

        Based on research showing AI systems preferentially cite passages of 134-167 words \
        that are self-contained, fact-rich, and answer questions directly.

        Dimensions:
        1. Answer Block Quality (30%) — optimal word count, definitions, structure
        2. Self-Containment (25%) — low pronoun density, no dangling references
        3. Structural Readability (20%) — Flesch reading ease, sentence variety
        4. Statistical Density (15%) — percentages, currency, years, data points
        5. Uniqueness Signals (10%) — proper nouns, technical terms, specific numbers

        Returns composite score (0-100), per-dimension scores, letter grade (A-F), \
        and improvement recommendations.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "text": MCPSchemaProperty(
                    type: "string",
                    description: "The passage text to score for AI citability"
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
        let score = scorePassageCitability(text)

        var recommendations: [String] = []
        if score.wordCount < CitabilityConstants.optimalWordCountMin {
            recommendations.append("Expand passage to 134-167 words for optimal citability.")
        } else if score.wordCount > CitabilityConstants.optimalWordCountMax {
            recommendations.append("Consider breaking into shorter 134-167 word passages.")
        }
        if score.selfContainment < 70 {
            recommendations.append("Replace pronouns with specific nouns to improve self-containment.")
        }
        if score.statisticalDensity < 40 {
            recommendations.append("Add specific data points, percentages, or statistics.")
        }
        if score.answerBlockQuality < 60 {
            recommendations.append("Add definition patterns ('X is ...') or list structures.")
        }
        if score.structuralReadability < 60 {
            recommendations.append("Adjust sentence length and complexity for better readability.")
        }

        let output = """
        Passage Citability Analysis

        Composite Score: \(String(format: "%.1f", score.composite)) / 100
        Grade: \(score.grade)
        Word Count: \(score.wordCount) (optimal: \(CitabilityConstants.optimalWordCountMin)-\(CitabilityConstants.optimalWordCountMax))

        Dimension Scores:
          Answer Block Quality: \(String(format: "%.1f", score.answerBlockQuality)) / 100 (weight: 30%)
          Self-Containment:     \(String(format: "%.1f", score.selfContainment)) / 100 (weight: 25%)
          Structural Readability: \(String(format: "%.1f", score.structuralReadability)) / 100 (weight: 20%)
          Statistical Density:  \(String(format: "%.1f", score.statisticalDensity)) / 100 (weight: 15%)
          Uniqueness Signals:   \(String(format: "%.1f", score.uniquenessSignals)) / 100 (weight: 10%)
        \(recommendations.isEmpty ? "" : "\nRecommendations:\n" + recommendations.map { "  • \($0)" }.joined(separator: "\n"))
        """

        return .success(text: output)
    }
}

// MARK: - analyze_page_citability Tool

/// Analyze an entire page by splitting into passages and scoring each.
public struct AnalyzePageCitabilityTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "analyze_page_citability",
        description: """
        Analyze an entire page's citability by scoring individual passages.

        Splits text into passages (by paragraph breaks), scores each passage \
        for AI citability, then provides:
        - Best passage score (the most citable block)
        - Average passage score across all blocks
        - Grade distribution (A/B/C/D/F counts)
        - Top 3 most citable passages with scores
        - Overall page citability assessment

        Optionally compare against content benchmarks by specifying page_type.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "text": MCPSchemaProperty(
                    type: "string",
                    description: "Full page text content to analyze"
                ),
                "page_type": MCPSchemaProperty(
                    type: "string",
                    description: "Page type for benchmark comparison: homepage, blog, pillar, product, service, about, faq"
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
        let pageType = args.getStringOptional("page_type")

        guard !text.isEmpty else {
            return .success(text: """
            Page Citability Analysis

            Passages Analyzed: 0
            No content to analyze.
            """)
        }

        // Split into passages and limit to 50
        var passages = splitParagraphs(text)
        if passages.count > 50 {
            passages = Array(passages.prefix(50))
        }

        let scores = passages.map { scorePassageCitability($0) }

        let bestScore = scores.max(by: { $0.composite < $1.composite })
        let avgScore = scores.isEmpty ? 0.0 : scores.reduce(0.0) { $0 + $1.composite } / Double(scores.count)
        let overallGrade = citabilityGrade(for: avgScore)

        // Grade distribution
        var gradeDistribution: [String: Int] = ["A": 0, "B": 0, "C": 0, "D": 0, "F": 0]
        for score in scores {
            gradeDistribution[score.grade, default: 0] += 1
        }

        // Top 3 passages
        let ranked = scores.enumerated()
            .sorted { $0.element.composite > $1.element.composite }
            .prefix(3)

        var output = """
        Page Citability Analysis

        Passages Analyzed: \(scores.count)
        Best Passage Score: \(String(format: "%.1f", bestScore?.composite ?? 0)) / 100
        Average Score: \(String(format: "%.1f", avgScore)) / 100
        Overall Grade: \(overallGrade)

        Grade Distribution:
          A (80+): \(gradeDistribution["A"] ?? 0)
          B (65-79): \(gradeDistribution["B"] ?? 0)
          C (50-64): \(gradeDistribution["C"] ?? 0)
          D (35-49): \(gradeDistribution["D"] ?? 0)
          F (<35): \(gradeDistribution["F"] ?? 0)
        """

        if !ranked.isEmpty {
            output += "\n\nTop Passages:"
            for (index, element) in ranked {
                let preview = String(passages[index].prefix(80))
                    .replacingOccurrences(of: "\n", with: " ")
                output += "\n  #\(index + 1): \(String(format: "%.1f", element.composite)) (\(element.grade)) — \"\(preview)...\""
            }
        }

        if let pageType = pageType, let benchmark = ContentBenchmarks.all[pageType] {
            let totalWords = countWords(in: text)
            output += "\n\nBenchmark Comparison (\(pageType)):"
            output += "\n  Word Count: \(totalWords) (minimum: \(benchmark.minimumWords), ideal: \(benchmark.idealRangeMin)-\(benchmark.idealRangeMax))"
            if totalWords < benchmark.minimumWords {
                output += "\n  ⚠ Below minimum word count for \(pageType) page type."
            }
        }

        return .success(text: output)
    }
}
