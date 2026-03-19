# Design Proposal: Utility Tools

## 1. Objective

**Objective:** Implement the first 2 MCP tools as thin wrappers around the TextAnalysis foundation, establishing the MCPToolHandler pattern for all subsequent GeoSEO tools.
**Master Plan Reference:** Phase 1 — Foundation & Utility (Step 2)

These tools expose `countSyllables` and `pronounDensity` from TextAnalysis.swift as MCP-callable tools, plus add SchemaIntrospection test helpers and registration tests.

## 2. Proposed Architecture

**New Files:**
- `Sources/GeoSEOMCP/Tools/UtilityTools.swift` — 2 MCPToolHandler structs + registration function
- `Tests/GeoSEOMCPTests/Helpers/SchemaIntrospection.swift` — Schema extraction helpers
- `Tests/GeoSEOMCPTests/DomainTests/UtilityToolTests.swift` — Tool execution tests
- `Tests/GeoSEOMCPTests/SchemaContractTests/SchemaSmokeTests.swift` — Schema smoke tests
- `Tests/GeoSEOMCPTests/RegistrationTests/ToolRegistrationTests.swift` — Registration tests

**Modified Files:**
- `Sources/GeoSEOMCP/ToolRegistry.swift` — Add utility tools to `allToolHandlers()`

## 3. API Surface

### UtilityTools.swift

```swift
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

public struct CountSyllablesTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "count_syllables",
        description: """
        Count syllables in text for readability analysis.

        Counts syllables per word and total for a passage using a vowel-group
        heuristic with adjustments for silent-e, diphthongs, and hiatus patterns.
        Useful for Flesch readability scoring and content analysis.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "text": MCPSchemaProperty(type: "string", description: "The text to analyze"),
            ],
            required: ["text"]
        )
    )
    // Returns: total syllables, word count, average syllables per word,
    // and per-word breakdown for short texts
}

// MARK: - calculate_pronoun_density

public struct CalculatePronounDensityTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "calculate_pronoun_density",
        description: """
        Calculate pronoun density in text using Apple's NaturalLanguage framework.

        Uses NLTagger with lexical class tagging to identify pronouns.
        High pronoun density (>15%) reduces AI citability because pronouns
        create ambiguity without surrounding context.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "text": MCPSchemaProperty(type: "string", description: "The text to analyze"),
            ],
            required: ["text"]
        )
    )
    // Returns: pronoun count, word count, density percentage,
    // assessment (low/moderate/high), impact on citability
}
```

## 4. MCP Schema

### count_syllables
```json
{
  "name": "count_syllables",
  "inputSchema": {
    "type": "object",
    "properties": {
      "text": { "type": "string", "description": "The text to analyze" }
    },
    "required": ["text"]
  }
}
```

### calculate_pronoun_density
```json
{
  "name": "calculate_pronoun_density",
  "inputSchema": {
    "type": "object",
    "properties": {
      "text": { "type": "string", "description": "The text to analyze" }
    },
    "required": ["text"]
  }
}
```

## 5. Constraints & Compliance

- **Concurrency:** All tool structs are Sendable
- **Safety:** No force unwraps. Guard for missing/empty text argument.
- **Error handling:** Use `ToolError.missingRequiredArgument` for missing text, return informative results for empty text.

## 6. Dependencies

**Internal:** Constants.swift, TextAnalysis.swift (Step 1)
**External:** SwiftMCPServer (MCPToolHandler, MCPTool, etc.)

## 7. Test Strategy

### Tool Execution Tests (UtilityToolTests.swift)
- count_syllables: "hello world" → total 3, words 2, avg 1.5
- count_syllables: empty text → 0 total
- count_syllables: missing argument → error
- calculate_pronoun_density: "She went to the store" → density > 0
- calculate_pronoun_density: "The cat sat on the mat" → density ~0
- calculate_pronoun_density: empty text → density 0
- calculate_pronoun_density: missing argument → error

### Schema Smoke Tests (SchemaSmokeTests.swift)
- All tools have non-empty name and description
- All required params have descriptions
- Minimal valid args don't crash any tool

### Registration Tests (ToolRegistrationTests.swift)
- allToolHandlers() returns exactly 2 tools
- Tool names are unique
- Expected tool names present: count_syllables, calculate_pronoun_density

## 8. Open Questions

None.
