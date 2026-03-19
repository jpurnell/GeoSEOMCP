# GeoSEO MCP Server Master Plan

**Purpose:** Source of truth for project vision, architecture, and goals.

---

## Project Overview

### Mission
Provide computational GEO (Generative Engine Optimization) analysis tools via MCP (Model Context Protocol), enabling AI assistants to evaluate and score websites for visibility to AI-powered search engines (ChatGPT, Perplexity, Google Gemini, Google AI Overviews, Bing Copilot).

Based on research from Princeton, Georgia Tech, and IIT Delhi showing that AI systems preferentially cite passages of 134-167 words that are self-contained, fact-rich, and answer questions directly. Reimplements and improves the computational scoring logic from [geo-seo-claude](https://github.com/zubair-trabzada/geo-seo-claude).

### Target Users
- AI assistants (Claude, GPT) performing website audits via MCP tool calls
- SEO professionals using AI assistants for GEO analysis workflows
- Web developers optimizing sites for AI search engine visibility

### Key Differentiators
- Research-backed citability scoring with 5-dimension analysis
- Comprehensive AI crawler access analysis covering 14 crawlers across 3 tiers
- Platform-specific readiness scoring for 5 major AI search products
- Pure computation tools — LLM handles data gathering, tools handle scoring
- Deployed as remote MCP server (HTTPS + OAuth) via SwiftMCPServer

---

## Architecture

### Technology Stack
- **Language:** Swift 6.0
- **Framework:** SwiftMCPServer (reusable MCP infrastructure)
- **Protocol:** MCP SDK (swift-sdk 0.10+)
- **Transport:** Streamable HTTP with TLS, OAuth 2.0, API key auth
- **Build System:** Swift Package Manager
- **Testing:** Swift Testing framework

### Module Structure

```
GeoSEOMCP/
├── Sources/
│   ├── GeoSEOMCP/              # Library target
│   │   ├── Constants.swift     # Domain data: crawlers, weights, benchmarks
│   │   ├── TextAnalysis.swift  # Pure text analysis functions
│   │   ├── ToolRegistry.swift  # allToolHandlers() collector
│   │   ├── Resources.swift     # MCPResourceProvider
│   │   ├── Prompts.swift       # MCPPromptProvider
│   │   └── Tools/              # 10 category files, 29 tools total
│   └── GeoSEOMCPServer/
│       └── main.swift          # MCPServer.builder()...run()
├── Tests/
│   └── GeoSEOMCPTests/
│       ├── Helpers/            # Test infrastructure
│       ├── DomainTests/        # Per-category correctness tests
│       ├── SchemaContractTests/# Smoke tests
│       └── RegistrationTests/  # Registry tests
└── Package.swift
```

### Key Types

| Type | Purpose |
|------|---------|
| `AICrawler` | AI crawler definition: name, user-agent, tier, recommendation |
| `CrawlerTier` | Enum: tier1 (search), tier2 (ecosystem), tier3 (training) |
| `GEOWeights` | Static scoring weight constants for all composite formulas |
| `AIPlatform` | Enum: googleAIO, chatGPT, perplexity, gemini, bingCopilot |
| `ContentBenchmark` | Page-type word count and readability benchmarks |
| `SameAsPlatform` | Priority-ordered platform for sameAs schema auditing |
| `SecurityHeaderSpec` | Security header name and max point value |

---

## Current Status

### What's Working
- [x] Project scaffold (Package.swift, directory structure)
- [x] SwiftMCPServer dependency integrated
- [x] main.swift with builder pattern
- [x] Test helpers adapted from BusinessMathMCP
- [x] Development guidelines installed
- [ ] Constants.swift — domain data
- [ ] TextAnalysis.swift — text utility functions
- [ ] Tool categories 1-10 (29 tools)

### Known Issues
- None (greenfield project)

### Current Priorities
1. Constants & TextAnalysis foundation with TDD
2. Utility tools (count_syllables, calculate_pronoun_density)
3. Citability scoring tools
4. Crawler access tools

---

## Quality Standards

### Code Quality
- All code follows `01_CODING_RULES.md`
- Design-First TDD: DESIGN → RED → GREEN → REFACTOR → DOCUMENT → VERIFY
- Zero warnings in build output
- No force unwrap, no try!, division safety, iteration limits

### Documentation Quality
- DocC comments for all public functions and types
- Usage examples in documentation
- Executable documentation examples

### Testing Standards
- Swift Testing framework (never XCTest)
- Golden path + edge case + invalid input tests per function
- Floating-point tolerance (never direct equality for Double)
- All tests deterministic

---

## Error Registry

> **Purpose:** Single source of truth for all error types. Consult during Design Proposal
> phase to ensure no duplication. Update when new error types are introduced.

### Error Types

| Error Enum | Case | When Thrown | Module |
|------------|------|------------|--------|
| `ToolError` | `.missingRequiredArgument(name)` | Required tool argument not provided | SwiftMCPServer |
| `ToolError` | `.invalidArguments(message)` | Argument fails validation | SwiftMCPServer |

*GeoSEO tools use ToolError from SwiftMCPServer. Add domain-specific errors here as needed.*

### Error Design Principles
- Use `ToolError` from SwiftMCPServer for argument validation
- Return error results (isError: true) for domain logic failures
- Include actionable context in error messages

---

## Roadmap

### Phase 1: Foundation & Utility (Steps 0-2)
- [x] Project bootstrap
- [ ] Constants.swift (crawlers, weights, benchmarks)
- [ ] TextAnalysis.swift (syllable counting, text stats)
- [ ] Utility tools (2 tools)

### Phase 2: Core Analysis (Steps 3-6)
- [ ] Citability scoring (2 tools)
- [ ] Crawler access analysis (3 tools)
- [ ] llms.txt validation (2 tools)
- [ ] Content analysis (4 tools)

### Phase 3: Structured Data & Technical (Steps 7-8)
- [ ] Schema validation & generation (4 tools)
- [ ] Technical SEO scoring (5 tools)

### Phase 4: Platform & Composite (Steps 9-10)
- [ ] Brand authority scoring (3 tools)
- [ ] Platform readiness (1 tool)
- [ ] Composite scoring & classification (3 tools)

### Phase 5: Polish & Deploy (Steps 11-12)
- [ ] Resources & Prompts
- [ ] Deployment to roseclub.org:8081
- [ ] End-to-end validation

### Future Considerations
- HTML parsing tools (SwiftSoup dependency)
- Automated web scraping integration
- Historical score tracking and delta reporting
- Competitor comparison tools

---

**Last Updated:** 2026-03-19
