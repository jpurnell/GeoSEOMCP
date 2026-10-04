# GeoSEO MCP Server

A Model Context Protocol (MCP) server providing 29 tools for Generative Engine Optimization (GEO) analysis. Built in Swift, designed to help AI-assisted workflows evaluate and improve web content for visibility in AI-powered search engines.

## Requirements

- Swift 6.2+
- macOS 14+

## Installation

```bash
git clone https://github.com/jpurnell/GeoSEOMCP.git
cd GeoSEOMCP
swift build
```

Run the server:

```bash
swift run geoseo-mcp-server
```

### Running over HTTP

With no arguments the server speaks MCP over stdio. `--http <port>` starts the HTTP
transport instead, and as of SwiftMCPServer 5.0.0 that listener binds `127.0.0.1` — this
machine only — unless it is told otherwise:

```bash
# Local: reachable at localhost only. Right for development, and for a server that
# sits behind a reverse proxy on the same machine.
geoseo-mcp-server --http 8081

# Public: the deployment on roseclub.org is reached from other machines, so it has to
# ask for every interface. Without --host 0.0.0.0 it starts, logs
# "Listening on loopback only", and is unreachable from outside.
geoseo-mcp-server --http 8081 --host 0.0.0.0
```

Authentication is required either way: with no key configured every request is refused.
Create one with `geoseo-mcp-server --generate-key`, or supply `MCP_API_KEYS`.

When a call fails, the caller sees the message only if it was written for them — an
invalid argument, an unknown resource URI. Anything else is answered with a generic
sentence and a reference id, and the detail is in the server's log under that id.

## Tools

### Citability (2 tools)
- `score_passage_citability` — Score a passage across 5 citability dimensions
- `analyze_page_citability` — Score all passages on a page with grade distribution

### Content Analysis (4 tools)
- `calculate_flesch_readability` — Flesch reading ease score
- `analyze_content_statistics` — Word count, sentence structure, vocabulary metrics
- `calculate_eeat_score` — Experience, Expertise, Authoritativeness, Trustworthiness score
- `check_content_benchmarks` — Compare against page-type benchmarks

### Crawler Access (3 tools)
- `parse_robots_txt` — Parse robots.txt into structured data
- `analyze_ai_crawler_access` — Check which AI crawlers are allowed/blocked
- `calculate_ai_visibility_score` — Composite AI crawler accessibility score

### Schema & Structured Data (4 tools)
- `validate_json_ld` — Validate JSON-LD syntax and structure
- `audit_sameas_coverage` — Check sameAs property coverage across platforms
- `score_schema_completeness` — Score schema markup completeness
- `generate_schema_template` — Generate schema.org JSON-LD templates

### Technical SEO (5 tools)
- `score_technical_seo` — Composite technical SEO score
- `analyze_security_headers` — Evaluate HTTP security headers
- `analyze_heading_structure` — Validate heading hierarchy
- `audit_meta_tags` — Check meta tag coverage and quality
- `detect_ssr_capability` — Detect server-side rendering support

### Brand & Platform (4 tools)
- `calculate_brand_authority_score` — Multi-platform brand authority score
- `score_platform_presence` — Score presence on a specific platform
- `score_platform_readiness` — Readiness assessment for platform expansion
- `generate_platform_search_urls` — Generate platform-specific search URLs

### llms.txt (2 tools)
- `validate_llmstxt` — Validate llms.txt file format and content
- `categorize_urls_for_llmstxt` — Categorize URLs for llms.txt generation

### Composite (3 tools)
- `calculate_geo_composite_score` — Weighted composite GEO score across all dimensions
- `classify_audit_findings` — Classify and prioritize audit findings
- `detect_business_type` — Detect business type from page content

### Utility (2 tools)
- `count_syllables` — Count syllables in text
- `calculate_pronoun_density` — Calculate pronoun density ratio

## Architecture

```
Sources/
  GeoSEOMCP/          — Library target (tools, constants, text analysis)
    GeoSEOMCP.docc/   — DocC catalogue (landing page, curated topics)
  GeoSEOMCPServer/    — Executable target (server entry point)
Tests/
  GeoSEOMCPTests/     — 191 tests across domain, registration, contract, and error-disclosure suites
```

## Documentation

The library ships a DocC catalogue covering the full public API — the 29 tool handlers
plus the plain-Swift scoring functions underneath them, organized by analysis dimension.

```bash
swift package --disable-sandbox preview-documentation --target GeoSEOMCP
```

Every tool's logic is also callable directly, without MCP: `scorePassageCitability(_:)`,
`parseRobotsTxt(_:)`, `fleschReadingEase(totalWords:totalSentences:totalSyllables:)`, and
so on. No tool fetches a URL — callers supply the page text, robots.txt body, or response
headers, which keeps scoring deterministic and offline.

## MCP Client Configuration

Add to your MCP client configuration:

```json
{
  "mcpServers": {
    "geoseo": {
      "command": "/path/to/geoseo-mcp-server",
      "args": []
    }
  }
}
```

## License

MIT
