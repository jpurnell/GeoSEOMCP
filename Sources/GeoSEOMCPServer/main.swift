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

        Tool Categories:
        1. Citability Scoring - AI citation readiness analysis
        2. AI Crawler Access - robots.txt analysis for 14 AI crawlers
        3. llms.txt - Validation and URL categorization
        4. Schema/Structured Data - JSON-LD validation and generation
        5. Technical SEO - Security headers, meta tags, SSR detection
        6. Content Analysis - Readability, E-E-A-T, benchmarks
        7. Brand Authority - Platform presence scoring
        8. Platform Readiness - Per-platform checklists
        9. Composite Scoring - Overall GEO score
        10. Utility - Text analysis helpers
        """)
    .tools(allToolHandlers())
    .run()
