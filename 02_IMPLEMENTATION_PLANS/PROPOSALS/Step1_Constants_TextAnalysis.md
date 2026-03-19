# Design Proposal: Constants & TextAnalysis Foundation

## 1. Objective

**Objective:** Establish the domain data constants and shared text analysis utilities that all GeoSEO tools depend on.
**Master Plan Reference:** Phase 1 — Foundation & Utility (Steps 0-2)

These are pure data definitions and pure functions with no MCP protocol involvement. They form the foundation layer that every tool category will import.

## 2. Proposed Architecture

**New Files:**
- `Sources/GeoSEOMCP/Constants.swift` — All domain data: AI crawlers, scoring weights, content benchmarks, platform definitions, security headers, sameAs platforms
- `Sources/GeoSEOMCP/TextAnalysis.swift` — Pure text analysis functions: syllable counting, sentence/word counting, pronoun density, definition pattern detection, statistical element counting

**Modified Files:**
- None (greenfield)

**Module Placement:** Root of GeoSEOMCP library target (not in Tools/)

## 3. API Surface

### Constants.swift

```swift
// MARK: - AI Crawler Registry

public struct AICrawler: Sendable {
    public let name: String
    public let userAgent: String
    public let owner: String
    public let purpose: String
    public let tier: CrawlerTier
    public let recommendation: CrawlerRecommendation
}

public enum CrawlerTier: Int, Sendable, CaseIterable {
    case tier1 = 1  // Critical for AI search visibility (ALLOW)
    case tier2 = 2  // Important for broader AI ecosystem (ALLOW)
    case tier3 = 3  // Training-only (context-dependent)
}

public enum CrawlerRecommendation: String, Sendable {
    case allow = "ALLOW"
    case block = "BLOCK"
    case contextDependent = "CONTEXT_DEPENDENT"
}

public enum AICrawlerRegistry {
    public static let allCrawlers: [AICrawler]  // 14 crawlers
    public static let tier1Crawlers: [AICrawler] // 5: GPTBot, OAI-SearchBot, ChatGPT-User, ClaudeBot, PerplexityBot
    public static let tier2Crawlers: [AICrawler] // 5: Google-Extended, GoogleOther, Applebot-Extended, Amazonbot, FacebookBot
    public static let tier3Crawlers: [AICrawler] // 4: CCBot, anthropic-ai, Bytespider, cohere-ai
}

// MARK: - Scoring Weights

public enum GEOWeights {
    // Composite GEO score weights (sum = 1.0)
    public static let citability: Double = 0.25
    public static let brandAuthority: Double = 0.20
    public static let contentEEAT: Double = 0.20
    public static let technical: Double = 0.15
    public static let schema: Double = 0.10
    public static let platform: Double = 0.10

    // Citability sub-weights (sum = 1.0)
    public static let answerBlockQuality: Double = 0.30
    public static let selfContainment: Double = 0.25
    public static let structuralReadability: Double = 0.20
    public static let statisticalDensity: Double = 0.15
    public static let uniquenessSignals: Double = 0.10

    // AI Visibility sub-weights (sum = 1.0)
    public static let tier1Access: Double = 0.50
    public static let tier2Access: Double = 0.25
    public static let noBlanketBlocks: Double = 0.15
    public static let aiFiles: Double = 0.10

    // Technical SEO sub-weights (sum = 1.0)
    public static let ssrCapability: Double = 0.25
    public static let metaTags: Double = 0.15
    public static let crawlability: Double = 0.15
    public static let securityHeaders: Double = 0.10
    public static let coreWebVitals: Double = 0.10
    public static let mobileOptimization: Double = 0.10
    public static let urlStructure: Double = 0.05
    public static let serverResponse: Double = 0.05
    public static let additionalTechnical: Double = 0.05

    // Brand authority sub-weights (sum = 1.0)
    public static let youtube: Double = 0.25
    public static let reddit: Double = 0.25
    public static let wikipedia: Double = 0.20
    public static let linkedin: Double = 0.15
    public static let otherPlatforms: Double = 0.15
}

// MARK: - AI Platforms

public enum AIPlatform: String, CaseIterable, Sendable {
    case googleAIO = "google_aio"
    case chatGPT = "chatgpt"
    case perplexity = "perplexity"
    case gemini = "gemini"
    case bingCopilot = "bing_copilot"
}

// MARK: - Content Benchmarks

public struct ContentBenchmark: Sendable {
    public let pageType: String
    public let minimumWords: Int
    public let idealRangeMin: Int
    public let idealRangeMax: Int
    public let targetFleschMin: Double
    public let targetFleschMax: Double
}

public enum ContentBenchmarks {
    public static let all: [String: ContentBenchmark]  // Keyed by page type
    // Types: homepage, blog, pillar, product, service, about, faq
}

// MARK: - sameAs Platforms

public struct SameAsPlatform: Sendable {
    public let name: String
    public let urlPattern: String  // substring to match in sameAs URLs
    public let priority: Int       // 1 = highest
    public let maxPoints: Double
}

public enum SameAsPlatforms {
    public static let all: [SameAsPlatform]
    // Wikipedia (1, 3pts), Wikidata (2, 3pts), LinkedIn (3, 2pts),
    // YouTube (4, 2pts), Twitter (5, 2pts), Facebook (6, 1pt),
    // GitHub (7, 1pt), Crunchbase (8, 1pt)  — total 15 pts max
}

// MARK: - Security Headers

public struct SecurityHeaderSpec: Sendable {
    public let name: String
    public let headerKey: String
    public let maxPoints: Double
}

public enum SecurityHeaders {
    public static let all: [SecurityHeaderSpec]
    // HSTS (20), CSP (20), X-Frame-Options (15),
    // X-Content-Type-Options (15), Referrer-Policy (15), Permissions-Policy (15)
}

// MARK: - Citability

public enum CitabilityConstants {
    public static let optimalWordCountMin: Int = 134
    public static let optimalWordCountMax: Int = 167
    public static let gradeA: Double = 80.0
    public static let gradeB: Double = 65.0
    public static let gradeC: Double = 50.0
    public static let gradeD: Double = 35.0
}
```

### TextAnalysis.swift

```swift
/// Count syllables in a single English word.
/// Uses a vowel-group heuristic with common adjustments.
public func countSyllables(in word: String) -> Int

/// Count total syllables in a text passage.
public func countPassageSyllables(_ text: String) -> Int

/// Count sentences (splits on .!? followed by whitespace or end).
public func countSentences(in text: String) -> Int

/// Count words (whitespace-separated tokens).
public func countWords(in text: String) -> Int

/// Split text into paragraphs (double-newline separated).
public func splitParagraphs(_ text: String) -> [String]

/// Calculate pronoun density (pronoun count / total words).
/// Returns 0.0 for empty text.
public func pronounDensity(in text: String) -> Double

/// Check if text contains a definition pattern ("X is ...", "X refers to ...", etc.).
public func containsDefinitionPattern(_ text: String) -> Bool

/// Count statistical elements (numbers with %, $, dates, named sources).
public func countStatisticalElements(in text: String) -> Int

/// Calculate Flesch Reading Ease score.
/// Formula: 206.835 - 1.015(words/sentences) - 84.6(syllables/words)
/// Returns NaN if sentences or words is zero.
public func fleschReadingEase(totalWords: Int, totalSentences: Int, totalSyllables: Int) -> Double

/// Calculate Flesch-Kincaid Grade Level.
/// Formula: 0.39(words/sentences) + 11.8(syllables/words) - 15.59
/// Returns NaN if sentences or words is zero.
public func fleschKincaidGradeLevel(totalWords: Int, totalSentences: Int, totalSyllables: Int) -> Double
```

## 4. MCP Schema

Not applicable — these are internal types and functions, not MCP tools. They will be consumed by the tool handlers in Steps 2-10.

## 5. Constraints & Compliance

- **Concurrency:** All types are Sendable (structs, enums with Sendable conformance)
- **Generics:** Not applicable (text analysis operates on String/Int/Double, not generic Real)
- **Safety:** No force unwraps. Division safety in Flesch formulas (return NaN for zero denominators). Guard clauses for empty inputs.
- **Iteration limits:** Syllable counting iterates over characters in a word (bounded by word length). No unbounded loops.
- **Determinism:** All functions are pure and deterministic.

## 6. Backend Abstraction

Not applicable — text analysis is lightweight CPU-only computation.

## 7. Dependencies

**Internal Dependencies:** None (foundation layer)
**External Dependencies:** Foundation (for regex/string processing)

## 8. Test Strategy

**Test File:** `Tests/GeoSEOMCPTests/DomainTests/TextAnalysisDomainTests.swift`

**Test Categories:**

### Syllable Counting
- Golden path: "hello" → 2, "beautiful" → 3, "the" → 1, "area" → 3
- Edge: empty string → 0, single letter "a" → 1
- Multi-word: "hello world" (passage) → 4
- Silent-e: "cake" → 1, "like" → 1
- Diphthongs: "coin" → 1, "loud" → 1

**Reference Truth:** Manual phonetic analysis confirmed against Merriam-Webster syllable counts.

### Sentence Counting
- Golden path: "Hello. World! Really?" → 3
- Abbreviations: "Dr. Smith went home." → 1 (known limitation: abbreviation periods)
- Edge: empty string → 0, no punctuation → 1 (treat as one sentence)

### Word Counting
- Golden path: "hello world" → 2
- Multiple spaces: "hello  world" → 2
- Edge: empty string → 0, single word → 1

### Pronoun Density
- Golden path: "I went to my house" → 2/5 = 0.4
- No pronouns: "The cat sat on the mat" → 0.0
- Edge: empty string → 0.0

### Definition Patterns
- Positive: "SEO is the process of optimizing" → true
- Positive: "GEO refers to the practice of" → true
- Negative: "We provide great services" → false
- Edge: empty string → false

### Statistical Elements
- Golden path: "Revenue grew 25% to $1.2M in 2024" → 3 (%, $, year)
- No stats: "This is a simple sentence" → 0

### Flesch Readability
- Known value: 200 words, 10 sentences, 300 syllables
  - Reading Ease = 206.835 - 1.015*(200/10) - 84.6*(300/200) = 206.835 - 20.3 - 126.9 = 59.635
  - Grade Level = 0.39*(200/10) + 11.8*(300/200) - 15.59 = 7.8 + 17.7 - 15.59 = 9.91
- Edge: 0 words → NaN, 0 sentences → NaN

**Validation Trace:** Flesch formula validated against manual calculation above.

## 9. Architecture Decision Review

- [x] Reviewed `06_ARCHITECTURE_DECISIONS.md` for related decisions
- [x] Does this supersede an existing ADR? No
- [x] New ADR required? No

## 10. Open Questions

None — the API is straightforward pure functions and static data.

## 11. Documentation Strategy

**Documentation Type:** API Docs Only

All public functions get `///` DocC comments with parameter descriptions and return value documentation. No narrative article needed — these are simple utility functions.
