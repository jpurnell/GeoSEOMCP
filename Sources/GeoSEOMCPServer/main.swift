import Foundation
import GeoSEOMCP
import SwiftMCPServer

try await MCPServer.builder()
    .serverName("GeoSEO MCP Server")
    .serverVersion("1.0.0")
    .serverInstructions("""
        Generative Engine Optimization (GEO) analysis server for AI search visibility.

        Analyzes websites for visibility to AI-powered search engines including
        ChatGPT, Perplexity, Google Gemini, Google AI Overviews, and Bing Copilot.

        **Capabilities**:
        - 29 computational tools across 10 categories
        - Research-backed citability scoring (5-dimension analysis)
        - 14 AI crawler access analysis across 3 tiers
        - Platform-specific readiness scoring for 5 AI search products
        - JSON-LD validation and template generation
        - 16 resources (documentation, templates, examples)
        - 5 prompt templates for guided analysis workflows

        **Tool Categories**:
        1. Utility: Syllable counting, pronoun density
        2. Citability: Passage and page citability scoring
        3. Crawler Access: robots.txt parsing, AI crawler analysis, visibility scoring
        4. llms.txt: Validation and URL categorization
        5. Content Analysis: Flesch readability, content stats, E-E-A-T, benchmarks
        6. Schema: JSON-LD validation, sameAs audit, completeness, template generation
        7. Technical SEO: Security headers, headings, meta tags, SSR detection
        8. Brand Authority: Brand scoring, platform presence, search URLs
        9. Platform Readiness: Per-platform optimization checklists
        10. Composite: GEO composite score, findings classification, business type detection

        **Resources**: Access GEO documentation, JSON-LD templates, and audit examples
        **Prompts**: Use prompt templates for guided GEO analysis workflows
        """)
    .tools(allToolHandlers())
    .resourceProvider(ResourceProvider())
    .promptProvider(PromptProvider())
    .run()
