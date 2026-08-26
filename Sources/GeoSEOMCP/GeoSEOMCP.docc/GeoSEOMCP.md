# ``GeoSEOMCP``

Analyze web content for visibility in AI-powered search engines.

## Overview

GeoSEOMCP is the library half of a Model Context Protocol server for Generative
Engine Optimization — the practice of shaping a page so that assistants like
ChatGPT, Claude, and Perplexity can reach it, parse it, and cite it.

The package exposes the same capability at two levels:

- **As MCP tools.** ``allToolHandlers()`` returns all 29 registered handlers,
  ready to hand to an `MCPServer`. The `geoseo-mcp-server` executable does
  exactly this and nothing more.
- **As plain Swift functions.** Every tool's scoring logic is a free function
  with no MCP dependency — ``scorePassageCitability(_:)``, ``parseRobotsTxt(_:)``,
  ``fleschReadingEase(totalWords:totalSentences:totalSyllables:)``. Call them
  directly when you want the analysis without the protocol.

Scoring is deterministic and offline. No tool fetches a URL; callers supply the
page text, the robots.txt body, or the response headers, which keeps results
reproducible and keeps the server usable in sandboxed environments.

### Analysis dimensions

Nine groups of tools cover the dimensions that determine whether an AI engine
can cite a page:

| Dimension | What it measures |
| --- | --- |
| Citability | Whether a passage stands alone well enough to be quoted |
| Content analysis | Readability, structure, and E-E-A-T signals |
| Crawler access | Which AI crawlers robots.txt admits |
| Schema | JSON-LD validity, completeness, and `sameAs` coverage |
| Technical SEO | Headers, heading hierarchy, meta tags, SSR |
| Brand & platform | Presence and authority across AI platforms |
| llms.txt | Validity of the emerging llms.txt convention |
| Composite | Weighted rollups across all of the above |
| Utility | Syllable counting and pronoun density primitives |

``CalculateGEOCompositeScoreTool`` — exposed as the `calculate_geo_composite_score`
tool — combines these into a single weighted figure using ``GEOWeights``.

## Topics

### Essentials

- ``allToolHandlers()``
- ``GeoSEOResult``
- ``ResultType``
- ``ScorePayload``
- ``JSONValue``

### Serving over MCP

- ``PromptProvider``
- ``ResourceProvider``
- ``ResourceError``

### Citability

- ``scorePassageCitability(_:)``
- ``citabilityGrade(for:)``
- ``CitabilityScore``
- ``CitabilityConstants``
- ``getCitabilityTools()``
- ``ScorePassageCitabilityTool``
- ``AnalyzePageCitabilityTool``

### Text analysis

- ``countWords(in:)``
- ``countSentences(in:)``
- ``tokenizeWords(_:)``
- ``splitParagraphs(_:)``
- ``countPronouns(in:)``
- ``pronounDensity(in:)``
- ``countSyllables(in:)``
- ``countPassageSyllables(_:)``
- ``containsDefinitionPattern(_:)``
- ``countStatisticalElements(in:)``
- ``containsListStructure(_:)``

### Readability

- ``fleschReadingEase(totalWords:totalSentences:totalSyllables:)``
- ``fleschKincaidGradeLevel(totalWords:totalSentences:totalSyllables:)``
- ``getContentAnalysisTools()``
- ``CalculateFleschReadabilityTool``
- ``AnalyzeContentStatisticsTool``
- ``CalculateEEATScoreTool``
- ``CheckContentBenchmarksTool``
- ``ContentBenchmark``
- ``ContentBenchmarks``

### Crawler access

- ``parseRobotsTxt(_:)``
- ``analyzeAICrawlerAccess(rules:)``
- ``calculateAIVisibilityScore(access:hasLlmsTxt:hasAiTxt:)``
- ``RobotsTxtDirective``
- ``CrawlerAccessResult``
- ``AICrawler``
- ``AICrawlerRegistry``
- ``CrawlerTier``
- ``CrawlerRecommendation``
- ``getCrawlerAccessTools()``
- ``ParseRobotsTxtTool``
- ``AnalyzeAICrawlerAccessTool``
- ``CalculateAIVisibilityScoreTool``

### Schema and structured data

- ``getSchemaTools()``
- ``ValidateJsonLdTool``
- ``AuditSameAsCoverageTool``
- ``ScoreSchemaCompletenessTool``
- ``GenerateSchemaTemplateTool``
- ``SameAsPlatform``
- ``SameAsPlatforms``

### Technical SEO

- ``getTechnicalSEOTools()``
- ``ScoreTechnicalSEOTool``
- ``AnalyzeSecurityHeadersTool``
- ``AnalyzeHeadingStructureTool``
- ``AuditMetaTagsTool``
- ``DetectSSRCapabilityTool``
- ``SecurityHeaderSpec``
- ``SecurityHeaders``

### Brand and platform presence

- ``getBrandPlatformTools()``
- ``CalculateBrandAuthorityScoreTool``
- ``ScorePlatformPresenceTool``
- ``ScorePlatformReadinessTool``
- ``GeneratePlatformSearchUrlsTool``
- ``AIPlatform``

### llms.txt

- ``validateLlmsTxt(_:)``
- ``categorizeUrlsForLlmsTxt(_:)``
- ``LlmsTxtValidationResult``
- ``URLCategory``
- ``getLlmsTxtTools()``
- ``ValidateLlmsTxtTool``
- ``CategorizeUrlsForLlmsTxtTool``

### Composite scoring

- ``GEOWeights``
- ``getCompositeTools()``
- ``CalculateGEOCompositeScoreTool``
- ``ClassifyAuditFindingsTool``
- ``DetectBusinessTypeTool``

### Utilities

- ``getUtilityTools()``
- ``CountSyllablesTool``
- ``CalculatePronounDensityTool``
