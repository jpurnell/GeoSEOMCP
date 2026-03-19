# Design Proposal: Citability Scoring Tools

## 1. Objective

**Objective:** Implement passage-level and page-level citability scoring based on Princeton/Georgia Tech/IIT Delhi research showing AI systems preferentially cite passages of 134-167 words that are self-contained, fact-rich, and answer questions directly.
**Master Plan Reference:** Phase 2 — Core Analysis (Step 3)

## 2. Proposed Architecture

**New Files:**
- `Sources/GeoSEOMCP/Tools/CitabilityTools.swift` — 2 MCPToolHandler structs + registration function
- `Tests/GeoSEOMCPTests/DomainTests/CitabilityToolTests.swift` — Tool execution tests

**Modified Files:**
- `Sources/GeoSEOMCP/ToolRegistry.swift` — Add citability tools to `allToolHandlers()`

## 3. API Surface

### CitabilityTools.swift

```swift
/// Returns all citability scoring tools.
public func getCitabilityTools() -> [any MCPToolHandler]

// MARK: - score_passage_citability

/// Score a single text passage for AI citability across 5 dimensions.
///
/// Dimensions (weights from GEOWeights):
/// 1. Answer Block Quality (30%) — word count in optimal 134-167 range,
///    contains definition patterns, contains list structures
/// 2. Self-Containment (25%) — low pronoun density, no dangling references
/// 3. Structural Readability (20%) — Flesch reading ease 40-60,
///    sentence variety, paragraph structure
/// 4. Statistical Density (15%) — percentages, currency, years, named sources
/// 5. Uniqueness Signals (10%) — specific names, numbers, technical terms
///
/// Returns: composite score (0-100), per-dimension scores, letter grade, recommendations
public struct ScorePassageCitabilityTool: MCPToolHandler, Sendable

// MARK: - analyze_page_citability

/// Analyze an entire page by splitting into passages and scoring each.
///
/// Splits text into passages (by paragraphs or double-newlines), scores
/// each passage individually, then aggregates:
/// - Best passage score (the most citable block)
/// - Average passage score
/// - Grade distribution (how many A/B/C/D/F passages)
/// - Top 3 most citable passages with their scores
/// - Recommendations for improvement
///
/// Input: full page text + optional page_type for benchmark comparison
public struct AnalyzePageCitabilityTool: MCPToolHandler, Sendable
```

## 4. MCP Schema

### score_passage_citability
```json
{
  "name": "score_passage_citability",
  "inputSchema": {
    "type": "object",
    "properties": {
      "text": { "type": "string", "description": "The passage text to score for AI citability" }
    },
    "required": ["text"]
  }
}
```

### analyze_page_citability
```json
{
  "name": "analyze_page_citability",
  "inputSchema": {
    "type": "object",
    "properties": {
      "text": { "type": "string", "description": "Full page text content to analyze" },
      "page_type": { "type": "string", "description": "Optional page type for benchmark comparison (homepage, blog, pillar, product, service, about, faq)" }
    },
    "required": ["text"]
  }
}
```

## 5. Scoring Algorithm

### Passage Citability Score (0-100)

**Dimension 1: Answer Block Quality (30%)**
- Word count score: 100 if in 134-167 range, scaled down outside range
  - <50 words: score = wordCount * 2 (max 100)
  - 50-133: linear scale from 60 to 100
  - 134-167: score = 100
  - 168-250: linear scale from 100 to 70
  - >250: score = max(30, 70 - (wordCount - 250) / 5)
- Definition pattern bonus: +15 if containsDefinitionPattern
- List structure bonus: +10 if containsListStructure
- Cap at 100

**Dimension 2: Self-Containment (25%)**
- Start at 100
- Pronoun density penalty: -(density * 200), capped at -60
- Short passage penalty: -20 if <50 words (likely incomplete)
- Cap at 0-100

**Dimension 3: Structural Readability (20%)**
- Flesch Reading Ease mapping:
  - 40-60 (ideal for technical content): 100
  - 30-40 or 60-70: 80
  - 20-30 or 70-80: 60
  - <20 or >80: 40
- Sentence count bonus: +10 if 3-7 sentences (well-structured block)
- Cap at 100

**Dimension 4: Statistical Density (15%)**
- Per statistical element: +20 points (capped at 100)
- 0 elements: 0, 1: 20, 2: 40, 3: 60, 4: 80, 5+: 100

**Dimension 5: Uniqueness Signals (10%)**
- Count capitalized non-sentence-start words (proper nouns): +15 each
- Count numbers in text: +10 each
- Count words >10 characters (technical terms): +10 each
- Cap at 100

**Composite:** weighted sum using GEOWeights citability sub-weights

**Grade:**
- A: ≥80, B: ≥65, C: ≥50, D: ≥35, F: <35

## 6. Constraints & Compliance

- **Concurrency:** Tool structs are Sendable, scoring functions are pure
- **Safety:** No force unwraps. Guard for empty text. NaN-safe Flesch calculations.
- **Iteration limits:** Page analysis limits to first 50 passages to prevent runaway on huge texts.

## 7. Dependencies

**Internal:** Constants.swift (GEOWeights, CitabilityConstants), TextAnalysis.swift (all functions)
**External:** SwiftMCPServer (MCPToolHandler)

## 8. Test Strategy

### Passage Scoring Tests
- Well-structured 150-word factual passage → score ≥65 (B or better)
- Short vague passage (<50 words, pronouns) → score <45
- Empty text → score 0
- Definition-rich passage → Answer Block Quality dimension high
- Statistic-heavy passage → Statistical Density dimension high
- Grade boundary verification: known scores → correct grades

### Page Analysis Tests
- Multi-paragraph text → correct passage count
- Page with one great passage and several mediocre → best score high, average moderate
- Empty text → zero passages
- Single paragraph → 1 passage scored

## 9. Open Questions

None.
