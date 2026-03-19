import Foundation
import MCP
import SwiftMCPServer

// MARK: - Resource Definitions

/// Provides resource listings and content for GeoSEO MCP Server
public actor ResourceProvider: MCPResourceProvider {

    /// List all available resources
    public func listResources() -> [Resource] {
        return [
            // Documentation Resources
            Resource(
                name: "GEO Overview",
                uri: "docs://geo-overview",
                description: "Introduction to Generative Engine Optimization — what it is and why it matters",
                mimeType: "text/plain"
            ),
            Resource(
                name: "Citability Scoring Guide",
                uri: "docs://citability-scoring",
                description: "5-dimension citability scoring methodology based on Princeton/Georgia Tech research",
                mimeType: "text/plain"
            ),
            Resource(
                name: "AI Crawler Access Guide",
                uri: "docs://ai-crawler-access",
                description: "Complete reference for 14 AI crawlers across 3 tiers with robots.txt recommendations",
                mimeType: "text/plain"
            ),
            Resource(
                name: "llms.txt Specification",
                uri: "docs://llmstxt-spec",
                description: "Structure and validation rules for the llms.txt standard",
                mimeType: "text/plain"
            ),
            Resource(
                name: "Schema.org for AI Guide",
                uri: "docs://schema-for-ai",
                description: "JSON-LD structured data best practices for AI search visibility",
                mimeType: "text/plain"
            ),
            Resource(
                name: "GEO Scoring Weights Reference",
                uri: "docs://scoring-weights",
                description: "All scoring weights and formulas used in GEO composite scoring",
                mimeType: "text/plain"
            ),

            // Template Resources
            Resource(
                name: "robots.txt Template",
                uri: "template://robots-txt",
                description: "AI-optimized robots.txt template allowing all recommended crawlers",
                mimeType: "text/plain"
            ),
            Resource(
                name: "llms.txt Template",
                uri: "template://llms-txt",
                description: "Starter llms.txt template with proper structure",
                mimeType: "text/plain"
            ),
            Resource(
                name: "Organization JSON-LD Template",
                uri: "template://jsonld-organization",
                description: "Schema.org Organization JSON-LD template with sameAs and key properties",
                mimeType: "application/json"
            ),
            Resource(
                name: "Local Business JSON-LD Template",
                uri: "template://jsonld-local-business",
                description: "Schema.org LocalBusiness JSON-LD template with address and hours",
                mimeType: "application/json"
            ),
            Resource(
                name: "Article JSON-LD Template",
                uri: "template://jsonld-article",
                description: "Schema.org Article JSON-LD template with author and publisher",
                mimeType: "application/json"
            ),
            Resource(
                name: "Product JSON-LD Template",
                uri: "template://jsonld-product",
                description: "Schema.org Product JSON-LD template with offers and reviews",
                mimeType: "application/json"
            ),
            Resource(
                name: "SaaS/Software JSON-LD Template",
                uri: "template://jsonld-software",
                description: "Schema.org SoftwareApplication JSON-LD template for SaaS products",
                mimeType: "application/json"
            ),
            Resource(
                name: "Website + SearchAction JSON-LD Template",
                uri: "template://jsonld-website",
                description: "Schema.org WebSite JSON-LD with SearchAction for sitelinks search box",
                mimeType: "application/json"
            ),

            // Example Resources
            Resource(
                name: "Full GEO Audit Workflow",
                uri: "example://full-audit",
                description: "Step-by-step example of a complete GEO audit using all tool categories",
                mimeType: "text/plain"
            ),
            Resource(
                name: "Citability Improvement Example",
                uri: "example://citability-improvement",
                description: "Before-and-after example of improving passage citability for AI search",
                mimeType: "text/plain"
            ),
        ]
    }

    /// Read resource content by URI
    public func readResource(uri: String) async throws -> ReadResource.Result {
        switch uri {
        // Documentation
        case "docs://geo-overview":
            return .init(contents: [.text(geoOverviewDoc, uri: uri)])
        case "docs://citability-scoring":
            return .init(contents: [.text(citabilityScoringDoc, uri: uri)])
        case "docs://ai-crawler-access":
            return .init(contents: [.text(aiCrawlerAccessDoc, uri: uri)])
        case "docs://llmstxt-spec":
            return .init(contents: [.text(llmsTxtSpecDoc, uri: uri)])
        case "docs://schema-for-ai":
            return .init(contents: [.text(schemaForAIDoc, uri: uri)])
        case "docs://scoring-weights":
            return .init(contents: [.text(scoringWeightsDoc, uri: uri)])

        // Templates
        case "template://robots-txt":
            return .init(contents: [.text(robotsTxtTemplate, uri: uri)])
        case "template://llms-txt":
            return .init(contents: [.text(llmsTxtTemplate, uri: uri)])
        case "template://jsonld-organization":
            return .init(contents: [.text(jsonLDOrganizationTemplate, uri: uri, mimeType: "application/json")])
        case "template://jsonld-local-business":
            return .init(contents: [.text(jsonLDLocalBusinessTemplate, uri: uri, mimeType: "application/json")])
        case "template://jsonld-article":
            return .init(contents: [.text(jsonLDArticleTemplate, uri: uri, mimeType: "application/json")])
        case "template://jsonld-product":
            return .init(contents: [.text(jsonLDProductTemplate, uri: uri, mimeType: "application/json")])
        case "template://jsonld-software":
            return .init(contents: [.text(jsonLDSoftwareTemplate, uri: uri, mimeType: "application/json")])
        case "template://jsonld-website":
            return .init(contents: [.text(jsonLDWebsiteTemplate, uri: uri, mimeType: "application/json")])

        // Examples
        case "example://full-audit":
            return .init(contents: [.text(fullAuditExample, uri: uri)])
        case "example://citability-improvement":
            return .init(contents: [.text(citabilityImprovementExample, uri: uri)])

        default:
            throw ResourceError.notFound(uri)
        }
    }

    public init() {}
}

/// Resource-specific errors
public enum ResourceError: Error, LocalizedError {
    case notFound(String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let uri):
            return "Resource not found: \(uri)"
        }
    }
}

// MARK: - Documentation Content

private let geoOverviewDoc = """
# Generative Engine Optimization (GEO)

## What is GEO?

Generative Engine Optimization (GEO) is the practice of optimizing web content \
for visibility in AI-powered search engines. Unlike traditional SEO which focuses \
on ranking in link-based search results, GEO focuses on making content more likely \
to be cited, referenced, and surfaced by AI systems.

## Why GEO Matters

AI search engines are rapidly growing:
- **ChatGPT Search** (OpenAI) — real-time web browsing with citations
- **Perplexity** — AI-native search engine with source attribution
- **Google AI Overviews** — AI-generated summaries atop search results
- **Google Gemini** — conversational AI with web access
- **Bing Copilot** — Microsoft's AI-enhanced search

These systems don't just rank pages — they extract, synthesize, and cite \
specific passages. Content must be structured for extraction, not just discovery.

## The Research Foundation

Research from Princeton, Georgia Tech, and IIT Delhi shows that AI systems \
preferentially cite passages that are:
- **134-167 words** in length (optimal citation window)
- **Self-contained** — understandable without surrounding context
- **Fact-rich** — containing statistics, data points, and specific claims
- **Structurally clear** — using definition patterns, lists, and clear formatting
- **Low in pronouns** — using entity names instead of "it", "they", "this"

## GEO Scoring Framework

The GEO composite score evaluates 6 dimensions:
1. **Citability (25%)** — How well content is structured for AI citation
2. **Brand Authority (20%)** — Platform presence and brand signals
3. **E-E-A-T (20%)** — Experience, Expertise, Authoritativeness, Trustworthiness
4. **Technical SEO (15%)** — Server-side rendering, security, meta tags
5. **Schema (10%)** — Structured data completeness
6. **Platform Readiness (10%)** — AI platform-specific optimization

## GEO Audit Workflow

A complete GEO audit typically follows this sequence:
1. Analyze robots.txt for AI crawler access
2. Validate llms.txt presence and structure
3. Score passage citability across key pages
4. Evaluate structured data (JSON-LD)
5. Assess technical SEO signals
6. Calculate brand authority across platforms
7. Score per-platform readiness
8. Compute overall GEO composite score
9. Classify findings by priority
"""

private let citabilityScoringDoc = """
# Citability Scoring Methodology

## Overview

Citability scoring measures how likely AI systems are to extract and cite a passage. \
Based on research showing AI citation preferences, the score evaluates 5 dimensions.

## Dimensions and Weights

### 1. Answer Block Quality (30%)
Measures how well a passage answers questions directly.
- **Word count**: Optimal range is 134-167 words (100 points)
- **Definition patterns**: "X is...", "X refers to..." (+20 points)
- **Flesch readability**: 45-65 range is ideal for technical content

### 2. Self-Containment (25%)
Measures whether a passage is understandable without context.
- **Pronoun density**: Lower is better (pronouns = context dependency)
- Ideal: < 5% pronoun density = 100 points
- Penalty: > 15% pronoun density = 0 points

### 3. Structural Readability (20%)
Measures formatting signals that aid AI extraction.
- **List structures**: Bullet points, numbered lists
- **Sentence count**: 3-8 sentences per passage is ideal
- **Clear paragraph breaks**: Single, focused passages score higher

### 4. Statistical Density (15%)
Measures presence of citable facts and data.
- **Numbers and statistics**: "$10M", "25%", "3x increase"
- **Specific claims**: Quantified statements score higher
- **Data points per passage**: 2-4 is optimal

### 5. Uniqueness Signals (10%)
Measures distinctive language that stands out.
- **Capitalized terms**: Brand names, proper nouns
- **Technical vocabulary**: Domain-specific terminology
- **Unique phrasing**: Avoids generic boilerplate

## Grading Scale

| Grade | Score | Interpretation |
|-------|-------|----------------|
| A | 80-100 | Excellent — highly citable by AI systems |
| B | 65-79 | Good — likely to be cited with minor improvements |
| C | 50-64 | Average — needs optimization for AI citation |
| D | 35-49 | Below average — significant improvements needed |
| F | 0-34 | Poor — unlikely to be cited by AI systems |

## Tools

- `score_passage_citability` — Score a single passage (134-167 words ideal)
- `analyze_page_citability` — Score all passages on a page, with grade distribution
"""

private let aiCrawlerAccessDoc = """
# AI Crawler Access Guide

## Overview

AI search engines use web crawlers to access and index content. Controlling \
access via robots.txt directly impacts whether your content appears in AI search results.

## The 14 AI Crawlers (3 Tiers)

### Tier 1 — Critical for AI Search (ALLOW these)
These crawlers directly power AI search products. Blocking them removes your \
content from major AI search engines.

| Crawler | Owner | Purpose |
|---------|-------|---------|
| GPTBot | OpenAI | Training data for GPT models |
| OAI-SearchBot | OpenAI | ChatGPT search results |
| ChatGPT-User | OpenAI | Real-time browsing for ChatGPT |
| ClaudeBot | Anthropic | Training and search for Claude |
| PerplexityBot | Perplexity AI | Perplexity search engine |

### Tier 2 — Broader AI Ecosystem (ALLOW these)
These crawlers power secondary AI products and large platform ecosystems.

| Crawler | Owner | Purpose |
|---------|-------|---------|
| Google-Extended | Google | Gemini and AI Overviews training |
| GoogleOther | Google | Google R&D and AI projects |
| Applebot-Extended | Apple | Apple Intelligence and Siri |
| Amazonbot | Amazon | Alexa and Amazon AI services |
| FacebookBot | Meta | Meta AI training and features |

### Tier 3 — Training-Only (Context-Dependent)
These crawlers are primarily for model training. Decision depends on your \
business model and content licensing strategy.

| Crawler | Owner | Purpose |
|---------|-------|---------|
| CCBot | Common Crawl | Open dataset for AI training |
| anthropic-ai | Anthropic | Anthropic model training |
| Bytespider | ByteDance | TikTok and ByteDance AI training |
| cohere-ai | Cohere | Cohere model training |

## AI Visibility Score

The visibility score (0-100) is calculated as:
- Tier 1 access: 50% weight
- Tier 2 access: 25% weight
- No blanket blocks: 15% weight
- AI files (llms.txt, ai.txt): 10% weight

## Tools

- `parse_robots_txt` — Parse robots.txt content into structured rules
- `analyze_ai_crawler_access` — Check which AI crawlers are allowed/blocked
- `calculate_ai_visibility_score` — Compute the overall visibility score
"""

private let llmsTxtSpecDoc = """
# llms.txt Specification

## What is llms.txt?

llms.txt is a proposed standard (similar to robots.txt) that helps AI systems \
understand your website's content structure. It provides a human-and-machine-readable \
overview of your site.

## Format

The file must follow this markdown structure:

```markdown
# Site Name

> Brief description of the site (1-2 sentences)

## Section Name

- [Link Text](URL): Description
- [Link Text](URL): Description

## Another Section

- [Link Text](URL): Description
```

## Validation Rules

1. **Required H1**: Must start with exactly one H1 heading (site name)
2. **Optional blockquote**: Brief site description immediately after H1
3. **H2 sections**: Each section groups related links
4. **Link format**: `- [text](url): description` within sections
5. **No nested headings**: Only H1 and H2 are valid

## URL Categories

URLs are automatically categorized based on path patterns:
- **Products**: /pricing, /plans, /features, /product
- **Resources**: /blog, /docs, /guide, /tutorial, /help
- **Company**: /about, /team, /careers, /contact
- **Legal**: /privacy, /terms, /legal, /cookie
- **API**: /api, /developer, /sdk, /reference
- **Community**: /community, /forum, /discord, /slack

## Tools

- `validate_llmstxt` — Validate llms.txt content against the specification
- `categorize_urls_for_llmstxt` — Categorize website URLs into llms.txt sections
"""

private let schemaForAIDoc = """
# Schema.org Structured Data for AI Search

## Why Schema Matters for GEO

AI search engines use JSON-LD structured data to:
- Understand entity relationships
- Verify brand identity across platforms
- Extract structured facts for AI responses
- Build knowledge graph connections

## Critical Schema Types

### Organization
The foundation for brand identity. Must include:
- `name`, `url`, `logo`
- `sameAs` array linking to authoritative profiles
- `contactPoint` for customer service
- `description` for AI extraction

### LocalBusiness (extends Organization)
For businesses with physical locations:
- `address` with full postal details
- `geo` coordinates
- `openingHours` in structured format
- `telephone`

### Article / BlogPosting
For content pages:
- `author` with Person type and credentials
- `datePublished` and `dateModified`
- `publisher` with Organization reference
- `headline` and `description`

### Product
For e-commerce:
- `offers` with price and availability
- `aggregateRating` from reviews
- `brand` reference
- `sku` and `gtin`

### SoftwareApplication
For SaaS products:
- `applicationCategory`
- `operatingSystem`
- `offers` with pricing
- `aggregateRating`

### WebSite + SearchAction
For site-wide signals:
- `potentialAction` with SearchAction
- Enables sitelinks search box in results

## sameAs Best Practices

The `sameAs` property links your entity to authoritative profiles. \
Priority order for maximum AI visibility:

1. **Wikipedia** (3 pts) — Strongest authority signal
2. **Wikidata** (3 pts) — Structured knowledge base
3. **LinkedIn** (2 pts) — Professional authority
4. **YouTube** (2 pts) — Video presence
5. **Twitter/X** (2 pts) — Social presence
6. **Facebook** (1 pt) — Social presence
7. **GitHub** (1 pt) — Technical credibility
8. **Crunchbase** (1 pt) — Business data

## Tools

- `validate_json_ld` — Validate JSON-LD syntax and required properties
- `audit_sameas_coverage` — Score sameAs links by platform priority
- `score_schema_completeness` — Evaluate overall schema coverage
- `generate_schema_template` — Generate JSON-LD templates by business type
"""

private let scoringWeightsDoc = """
# GEO Scoring Weights Reference

## Composite GEO Score (sum = 1.0)

| Category | Weight | Description |
|----------|--------|-------------|
| Citability | 0.25 (25%) | AI citation readiness |
| Brand Authority | 0.20 (20%) | Platform presence signals |
| E-E-A-T | 0.20 (20%) | Content quality signals |
| Technical SEO | 0.15 (15%) | Technical optimization |
| Schema | 0.10 (10%) | Structured data completeness |
| Platform Readiness | 0.10 (10%) | Per-platform optimization |

## Citability Sub-Weights (sum = 1.0)

| Dimension | Weight | What it Measures |
|-----------|--------|-----------------|
| Answer Block Quality | 0.30 | Word count, definition patterns, readability |
| Self-Containment | 0.25 | Pronoun density (lower is better) |
| Structural Readability | 0.20 | Lists, sentence count, formatting |
| Statistical Density | 0.15 | Numbers, data points, statistics |
| Uniqueness Signals | 0.10 | Proper nouns, technical terms |

## AI Visibility Sub-Weights (sum = 1.0)

| Factor | Weight | What it Measures |
|--------|--------|-----------------|
| Tier 1 Access | 0.50 | GPTBot, OAI-SearchBot, ChatGPT-User, ClaudeBot, PerplexityBot |
| Tier 2 Access | 0.25 | Google-Extended, GoogleOther, Applebot-Extended, Amazonbot, FacebookBot |
| No Blanket Blocks | 0.15 | User-agent: * not blocking / |
| AI Files | 0.10 | llms.txt and ai.txt presence |

## Technical SEO Sub-Weights (sum = 1.0)

| Factor | Weight |
|--------|--------|
| SSR Capability | 0.25 |
| Meta Tags | 0.15 |
| Crawlability | 0.15 |
| Security Headers | 0.10 |
| Core Web Vitals | 0.10 |
| Mobile Optimization | 0.10 |
| URL Structure | 0.05 |
| Server Response | 0.05 |
| Additional | 0.05 |

## Brand Authority Sub-Weights (sum = 1.0)

| Platform | Weight |
|----------|--------|
| YouTube | 0.25 |
| Reddit | 0.25 |
| Wikipedia | 0.20 |
| LinkedIn | 0.15 |
| Other Platforms | 0.15 |

## Grading Scale

| Grade | Score Range | Interpretation |
|-------|------------|----------------|
| A | 80-100 | Excellent optimization |
| B | 65-79 | Good with room for improvement |
| C | 50-64 | Average, needs work |
| D | 35-49 | Below average |
| F | 0-34 | Significant optimization needed |
"""

// MARK: - Template Content

private let robotsTxtTemplate = """
# AI-Optimized robots.txt Template
# Generated by GeoSEO MCP Server
#
# This template allows all recommended AI crawlers while maintaining
# control over training-only crawlers.

User-agent: *
Allow: /

# Tier 1 — Critical for AI Search (ALLOW)
User-agent: GPTBot
Allow: /

User-agent: OAI-SearchBot
Allow: /

User-agent: ChatGPT-User
Allow: /

User-agent: ClaudeBot
Allow: /

User-agent: PerplexityBot
Allow: /

# Tier 2 — Broader AI Ecosystem (ALLOW)
User-agent: Google-Extended
Allow: /

User-agent: GoogleOther
Allow: /

User-agent: Applebot-Extended
Allow: /

User-agent: Amazonbot
Allow: /

User-agent: FacebookBot
Allow: /

# Tier 3 — Training-Only (customize based on your content strategy)
# Uncomment to block training-only crawlers:
# User-agent: CCBot
# Disallow: /
#
# User-agent: anthropic-ai
# Disallow: /
#
# User-agent: Bytespider
# Disallow: /
#
# User-agent: cohere-ai
# Disallow: /

# Standard crawlers
Sitemap: https://www.example.com/sitemap.xml
"""

private let llmsTxtTemplate = """
# Your Site Name

> Brief description of your website and its primary purpose.

## Products

- [Product Name](/product): Description of your main product or service
- [Pricing](/pricing): Pricing plans and options

## Resources

- [Blog](/blog): Latest articles and insights
- [Documentation](/docs): Technical documentation and guides
- [FAQ](/faq): Frequently asked questions

## Company

- [About](/about): Company background and mission
- [Team](/team): Meet the team
- [Contact](/contact): Get in touch

## Legal

- [Privacy Policy](/privacy): Privacy policy
- [Terms of Service](/terms): Terms of service
"""

private let jsonLDOrganizationTemplate = """
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Your Organization Name",
  "url": "https://www.example.com",
  "logo": "https://www.example.com/logo.png",
  "description": "Brief description of your organization",
  "foundingDate": "2020-01-01",
  "sameAs": [
    "https://en.wikipedia.org/wiki/Your_Organization",
    "https://www.wikidata.org/wiki/Q12345",
    "https://www.linkedin.com/company/your-org",
    "https://www.youtube.com/@your-org",
    "https://twitter.com/your_org",
    "https://www.facebook.com/your.org",
    "https://github.com/your-org",
    "https://www.crunchbase.com/organization/your-org"
  ],
  "contactPoint": {
    "@type": "ContactPoint",
    "telephone": "+1-555-555-5555",
    "contactType": "customer service",
    "availableLanguage": "English"
  }
}
"""

private let jsonLDLocalBusinessTemplate = """
{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": "Your Business Name",
  "url": "https://www.example.com",
  "logo": "https://www.example.com/logo.png",
  "description": "Brief description of your local business",
  "telephone": "+1-555-555-5555",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "123 Main Street",
    "addressLocality": "City",
    "addressRegion": "ST",
    "postalCode": "12345",
    "addressCountry": "US"
  },
  "geo": {
    "@type": "GeoCoordinates",
    "latitude": "40.7128",
    "longitude": "-74.0060"
  },
  "openingHoursSpecification": [
    {
      "@type": "OpeningHoursSpecification",
      "dayOfWeek": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
      "opens": "09:00",
      "closes": "17:00"
    }
  ],
  "sameAs": [
    "https://www.linkedin.com/company/your-business",
    "https://www.facebook.com/your.business"
  ]
}
"""

private let jsonLDArticleTemplate = """
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Article Title",
  "description": "Brief summary of the article",
  "url": "https://www.example.com/blog/article-slug",
  "datePublished": "2025-01-15T08:00:00Z",
  "dateModified": "2025-01-16T10:00:00Z",
  "author": {
    "@type": "Person",
    "name": "Author Name",
    "url": "https://www.example.com/team/author-name",
    "jobTitle": "Job Title",
    "sameAs": [
      "https://www.linkedin.com/in/author-name",
      "https://twitter.com/author_handle"
    ]
  },
  "publisher": {
    "@type": "Organization",
    "name": "Your Organization",
    "logo": {
      "@type": "ImageObject",
      "url": "https://www.example.com/logo.png"
    }
  },
  "image": "https://www.example.com/images/article-hero.jpg",
  "mainEntityOfPage": "https://www.example.com/blog/article-slug"
}
"""

private let jsonLDProductTemplate = """
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "Product Name",
  "description": "Product description",
  "url": "https://www.example.com/products/product-slug",
  "image": "https://www.example.com/images/product.jpg",
  "sku": "SKU-12345",
  "brand": {
    "@type": "Brand",
    "name": "Brand Name"
  },
  "offers": {
    "@type": "Offer",
    "price": "99.99",
    "priceCurrency": "USD",
    "availability": "https://schema.org/InStock",
    "url": "https://www.example.com/products/product-slug"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.5",
    "reviewCount": "150"
  }
}
"""

private let jsonLDSoftwareTemplate = """
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Your SaaS Product",
  "description": "Description of your software application",
  "url": "https://www.example.com",
  "applicationCategory": "BusinessApplication",
  "operatingSystem": "Web",
  "offers": {
    "@type": "AggregateOffer",
    "lowPrice": "0",
    "highPrice": "99",
    "priceCurrency": "USD",
    "offerCount": "3"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.7",
    "reviewCount": "500"
  },
  "author": {
    "@type": "Organization",
    "name": "Your Organization",
    "url": "https://www.example.com"
  }
}
"""

private let jsonLDWebsiteTemplate = """
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Your Website Name",
  "url": "https://www.example.com",
  "description": "Brief description of your website",
  "potentialAction": {
    "@type": "SearchAction",
    "target": {
      "@type": "EntryPoint",
      "urlTemplate": "https://www.example.com/search?q={search_term_string}"
    },
    "query-input": "required name=search_term_string"
  }
}
"""

// MARK: - Example Content

private let fullAuditExample = """
# Full GEO Audit Workflow Example

This example demonstrates a complete GEO audit using all tool categories.

## Step 1: AI Crawler Access

First, check if AI crawlers can access the site:

```
Tool: parse_robots_txt
Input: { "robots_txt_content": "<paste robots.txt content>" }

Tool: analyze_ai_crawler_access
Input: { "rules": [<parsed rules from above>] }

Tool: calculate_ai_visibility_score
Input: { "access_results": [<access results>], "has_llmstxt": true, "has_aitxt": false }
```

## Step 2: llms.txt Validation

Check if llms.txt exists and is properly formatted:

```
Tool: validate_llmstxt
Input: { "content": "<paste llms.txt content>" }
```

## Step 3: Citability Analysis

Score key pages for AI citation readiness:

```
Tool: score_passage_citability
Input: { "text": "<key passage from homepage>" }

Tool: analyze_page_citability
Input: { "passages": ["<passage 1>", "<passage 2>", ...] }
```

## Step 4: Content Analysis

Evaluate content quality and readability:

```
Tool: calculate_flesch_readability
Input: { "total_words": 500, "total_sentences": 25, "total_syllables": 750 }

Tool: analyze_content_statistics
Input: { "text": "<full page text>" }

Tool: calculate_eeat_score
Input: { "experience": 20, "expertise": 22, "authoritativeness": 18, "trustworthiness": 25 }

Tool: check_content_benchmarks
Input: { "page_type": "blog", "word_count": 1800, "flesch_score": 55.0 }
```

## Step 5: Schema Validation

Check structured data:

```
Tool: validate_json_ld
Input: { "json_ld": "<JSON-LD from page>" }

Tool: audit_sameas_coverage
Input: { "sameas_urls": ["https://linkedin.com/company/x", ...] }

Tool: score_schema_completeness
Input: { "has_organization": true, "has_website": true, ... }
```

## Step 6: Technical SEO

Evaluate technical signals:

```
Tool: analyze_security_headers
Input: { "headers": { "strict-transport-security": "max-age=31536000", ... } }

Tool: analyze_heading_structure
Input: { "headings": [{"level": 1, "text": "Main Title"}, ...] }

Tool: audit_meta_tags
Input: { "title": "Page Title", "description": "Meta description", ... }

Tool: detect_ssr_capability
Input: { "signals": ["has_next_data", "substantial_initial_content"] }

Tool: score_technical_seo
Input: { "security_score": 85, "heading_score": 90, ... }
```

## Step 7: Brand Authority

Score brand presence:

```
Tool: calculate_brand_authority_score
Input: { "youtube_score": 80, "reddit_score": 60, ... }

Tool: score_platform_presence
Input: { "platform": "youtube", "has_presence": true, ... }

Tool: generate_platform_search_urls
Input: { "brand_name": "Acme Corp" }
```

## Step 8: Platform Readiness

Check per-platform optimization:

```
Tool: score_platform_readiness
Input: { "platform": "google_aio", "checklist": {...} }
```

## Step 9: Composite Score

Calculate the overall GEO score:

```
Tool: calculate_geo_composite_score
Input: {
  "citability_score": 72,
  "brand_authority_score": 65,
  "eeat_score": 78,
  "technical_score": 85,
  "schema_score": 60,
  "platform_score": 55
}

Tool: classify_audit_findings
Input: { "findings": [{"area": "Schema", "current_score": 60, "target_score": 80}, ...] }

Tool: detect_business_type
Input: { "signals": ["pricing_page", "signup_cta", "api_docs"] }
```
"""

private let citabilityImprovementExample = """
# Citability Improvement Example

## Before (Score: ~35, Grade F)

"We offer great solutions for businesses. Our team has years of experience \
and we can help you achieve your goals. Contact us to learn more about what \
we can do for you. We're here to help with all your needs."

**Problems:**
- Too short (38 words, optimal is 134-167)
- High pronoun density ("we", "you", "us" = 30%+)
- No facts, statistics, or specific claims
- No definition patterns
- Generic language with no unique signals

## After (Score: ~78, Grade B)

"Acme Corp provides enterprise data analytics solutions that reduce operational \
costs by an average of 23% within the first year of implementation. Founded in \
2015, Acme Corp serves over 500 Fortune 1000 companies across 12 industries \
including healthcare, finance, and manufacturing. The platform processes over \
2 billion data points daily using proprietary machine learning algorithms, \
delivering actionable insights through customizable dashboards. Acme Corp's \
analytics suite includes predictive modeling, anomaly detection, and automated \
reporting capabilities. Independent analysis by Gartner positioned Acme Corp \
as a Leader in the 2024 Magic Quadrant for Analytics and Business Intelligence \
Platforms, citing the platform's ease of deployment and integration with existing \
enterprise systems as key differentiators."

**Improvements:**
- 120 words (approaching optimal range)
- Entity names instead of pronouns (Acme Corp, Gartner)
- Rich statistics (23%, 500 companies, 12 industries, 2B data points)
- Specific claims with sources (Gartner Magic Quadrant)
- Self-contained — understandable without any other context
- Technical vocabulary (machine learning, predictive modeling, anomaly detection)
"""
