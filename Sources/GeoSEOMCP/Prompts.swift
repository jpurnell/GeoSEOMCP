import Foundation
import MCP
import SwiftMCPServer

// MARK: - Prompt Definitions

/// Provides prompt templates for common GEO analysis tasks
public actor PromptProvider: MCPPromptProvider {

    /// List all available prompts
    public func listPrompts() -> [Prompt] {
        return [
            Prompt(
                name: "full_geo_audit",
                description: "Complete GEO audit workflow covering all analysis dimensions",
                arguments: [
                    Prompt.Argument(
                        name: "website_url",
                        description: "The website URL to audit (e.g., https://www.example.com)",
                        required: true
                    ),
                    Prompt.Argument(
                        name: "business_type",
                        description: "Business type: saas, ecommerce, local, media, agency (optional — will auto-detect)",
                        required: false
                    ),
                ]
            ),

            Prompt(
                name: "citability_analysis",
                description: "Analyze and improve content citability for AI search engines",
                arguments: [
                    Prompt.Argument(
                        name: "page_url",
                        description: "URL of the page to analyze",
                        required: true
                    ),
                    Prompt.Argument(
                        name: "target_grade",
                        description: "Target citability grade: A, B, or C (default: B)",
                        required: false
                    ),
                ]
            ),

            Prompt(
                name: "crawler_access_check",
                description: "Analyze robots.txt and AI crawler access for a website",
                arguments: [
                    Prompt.Argument(
                        name: "website_url",
                        description: "The website URL to check",
                        required: true
                    ),
                ]
            ),

            Prompt(
                name: "schema_audit",
                description: "Audit and improve JSON-LD structured data for AI visibility",
                arguments: [
                    Prompt.Argument(
                        name: "website_url",
                        description: "The website URL to audit",
                        required: true
                    ),
                    Prompt.Argument(
                        name: "business_type",
                        description: "Business type for template generation: organization, local-business, article, product, software, website",
                        required: false
                    ),
                ]
            ),

            Prompt(
                name: "platform_readiness_check",
                description: "Evaluate website readiness for specific AI search platforms",
                arguments: [
                    Prompt.Argument(
                        name: "website_url",
                        description: "The website URL to evaluate",
                        required: true
                    ),
                    Prompt.Argument(
                        name: "platforms",
                        description: "Comma-separated platforms: google_aio, chatgpt, perplexity, gemini, bing_copilot (default: all)",
                        required: false
                    ),
                ]
            ),
        ]
    }

    /// Get prompt content with arguments filled in
    public func getPrompt(name: String, arguments: [String: String]?) -> GetPrompt.Result {
        switch name {
        case "full_geo_audit":
            return getFullGEOAuditPrompt(arguments: arguments)
        case "citability_analysis":
            return getCitabilityAnalysisPrompt(arguments: arguments)
        case "crawler_access_check":
            return getCrawlerAccessCheckPrompt(arguments: arguments)
        case "schema_audit":
            return getSchemaAuditPrompt(arguments: arguments)
        case "platform_readiness_check":
            return getPlatformReadinessCheckPrompt(arguments: arguments)
        default:
            return GetPrompt.Result(
                description: "Unknown prompt",
                messages: [
                    Prompt.Message.user(.text(text: "Error: Prompt '\(name)' not found"))
                ]
            )
        }
    }

    public init() {}
}

// MARK: - Prompt Implementations

private func getFullGEOAuditPrompt(arguments: [String: String]?) -> GetPrompt.Result {
    let url = arguments?["website_url"] ?? "{website_url}"
    let businessType = arguments?["business_type"]

    var prompt = """
    Please perform a complete GEO (Generative Engine Optimization) audit for \(url).

    """

    if let businessType = businessType {
        prompt += "Business type: \(businessType)\n\n"
    } else {
        prompt += """
        First, detect the business type using `detect_business_type` with signals you \
        observe from the website.\n\n
        """
    }

    prompt += """
    Follow this audit workflow:

    **Phase 1: AI Crawler Access**
    1. Fetch the robots.txt from \(url)/robots.txt
    2. Use `parse_robots_txt` to parse the content
    3. Use `analyze_ai_crawler_access` to check all 14 AI crawlers
    4. Use `calculate_ai_visibility_score` with the access results
    5. Check if \(url)/llms.txt exists; if so, validate with `validate_llmstxt`

    **Phase 2: Content Analysis**
    6. Identify 3-5 key passages from the homepage and main pages
    7. Score each passage with `score_passage_citability`
    8. Use `analyze_page_citability` for the overall page assessment
    9. Use `analyze_content_statistics` on page text
    10. Use `calculate_flesch_readability` with the content stats
    11. Score E-E-A-T with `calculate_eeat_score` based on observed signals
    12. Use `check_content_benchmarks` for the page type

    **Phase 3: Structured Data**
    13. Extract JSON-LD from the page source
    14. Validate with `validate_json_ld`
    15. If Organization schema exists, audit sameAs with `audit_sameas_coverage`
    16. Score overall schema with `score_schema_completeness`

    **Phase 4: Technical SEO**
    17. Check response headers with `analyze_security_headers`
    18. Analyze heading structure with `analyze_heading_structure`
    19. Audit meta tags with `audit_meta_tags`
    20. Detect SSR capability with `detect_ssr_capability`
    21. Calculate technical composite with `score_technical_seo`

    **Phase 5: Brand & Platform**
    22. Use `generate_platform_search_urls` with the brand name
    23. Score platform presence for key platforms with `score_platform_presence`
    24. Calculate brand authority with `calculate_brand_authority_score`
    25. Score platform readiness for all 5 AI platforms with `score_platform_readiness`

    **Phase 6: Composite Score & Recommendations**
    26. Calculate the GEO composite score with `calculate_geo_composite_score`
    27. Classify all findings with `classify_audit_findings`
    28. Provide prioritized recommendations organized by:
        - Critical (address immediately)
        - High (address soon)
        - Medium (worth improving)
        - Low (minor optimizations)

    Present results in a clear, organized report with scores for each category \
    and actionable recommendations.
    """

    return GetPrompt.Result(
        description: "Full GEO audit for \(url)",
        messages: [
            Prompt.Message.user(.text(text: prompt))
        ]
    )
}

private func getCitabilityAnalysisPrompt(arguments: [String: String]?) -> GetPrompt.Result {
    let url = arguments?["page_url"] ?? "{page_url}"
    let targetGrade = arguments?["target_grade"] ?? "B"

    let prompt = """
    Please analyze the content citability for \(url) with a target grade of \(targetGrade).

    **Step 1: Content Extraction**
    - Fetch the page content from \(url)
    - Identify all substantive text passages (paragraphs of 50+ words)
    - Focus on passages that could serve as AI citation candidates

    **Step 2: Passage Scoring**
    - Score each passage with `score_passage_citability`
    - Pay attention to:
      - Word count (optimal: 134-167 words)
      - Pronoun density (lower is better)
      - Definition patterns ("X is...", "X refers to...")
      - Statistical elements (numbers, percentages, data points)
      - Structural readability (lists, clear sentences)

    **Step 3: Page-Level Analysis**
    - Use `analyze_page_citability` with all passages
    - Review the grade distribution across the page

    **Step 4: Improvement Recommendations**
    For each passage scoring below grade \(targetGrade), provide:
    - Current score and grade
    - Specific issues (e.g., "too many pronouns", "no statistics")
    - Rewritten version that addresses the issues
    - Expected score improvement

    **Step 5: Summary**
    - Overall citability assessment
    - Top 3 quick wins for improving citability
    - Passages that are already strong citations (if any)
    """

    return GetPrompt.Result(
        description: "Citability analysis for \(url) targeting grade \(targetGrade)",
        messages: [
            Prompt.Message.user(.text(text: prompt))
        ]
    )
}

private func getCrawlerAccessCheckPrompt(arguments: [String: String]?) -> GetPrompt.Result {
    let url = arguments?["website_url"] ?? "{website_url}"

    let prompt = """
    Please check AI crawler access for \(url).

    **Step 1: Fetch robots.txt**
    - Retrieve \(url)/robots.txt
    - Parse with `parse_robots_txt`

    **Step 2: Analyze Crawler Access**
    - Use `analyze_ai_crawler_access` with the parsed rules
    - Review which of the 14 AI crawlers are allowed vs blocked
    - Pay special attention to Tier 1 crawlers (GPTBot, OAI-SearchBot, ChatGPT-User, \
    ClaudeBot, PerplexityBot)

    **Step 3: Calculate Visibility Score**
    - Check if \(url)/llms.txt exists
    - Check if \(url)/ai.txt exists
    - Use `calculate_ai_visibility_score` with all signals

    **Step 4: Check llms.txt**
    - If llms.txt exists, validate with `validate_llmstxt`
    - If it doesn't exist, suggest creating one using `categorize_urls_for_llmstxt` \
    with the site's main URLs

    **Step 5: Recommendations**
    Report:
    - Current AI visibility score and what it means
    - Which critical crawlers are blocked (if any)
    - Recommended robots.txt changes (provide exact directives)
    - Whether llms.txt should be created or improved
    - Priority order for fixes
    """

    return GetPrompt.Result(
        description: "AI crawler access check for \(url)",
        messages: [
            Prompt.Message.user(.text(text: prompt))
        ]
    )
}

private func getSchemaAuditPrompt(arguments: [String: String]?) -> GetPrompt.Result {
    let url = arguments?["website_url"] ?? "{website_url}"
    let businessType = arguments?["business_type"]

    var prompt = """
    Please audit the JSON-LD structured data for \(url).

    **Step 1: Extract Schema**
    - Fetch the page source from \(url)
    - Find all <script type="application/ld+json"> blocks
    - Parse each JSON-LD block

    **Step 2: Validate Each Block**
    - Use `validate_json_ld` for each JSON-LD block found
    - Check for required @context and @type
    - Review type-specific required properties

    **Step 3: Audit sameAs Coverage**
    - If Organization schema exists, extract the sameAs array
    - Use `audit_sameas_coverage` to score platform coverage
    - Identify missing high-priority platforms (Wikipedia, Wikidata, LinkedIn)

    **Step 4: Score Completeness**
    - Use `score_schema_completeness` with what schema types are present
    - Identify which schema types are missing

    """

    if let businessType = businessType {
        prompt += """
        **Step 5: Generate Templates**
        - Use `generate_schema_template` with type "\(businessType)" for any missing schema
        - Customize the template with actual site data where available

        """
    } else {
        prompt += """
        **Step 5: Generate Templates**
        - Based on the detected business type, use `generate_schema_template` for missing schema
        - Recommend the most impactful schema types to add first

        """
    }

    prompt += """
    **Step 6: Report**
    - Current schema coverage score
    - Validation issues found
    - sameAs coverage gaps
    - Recommended schema additions (with ready-to-use JSON-LD)
    - Priority order for implementation
    """

    return GetPrompt.Result(
        description: "Schema audit for \(url)",
        messages: [
            Prompt.Message.user(.text(text: prompt))
        ]
    )
}

private func getPlatformReadinessCheckPrompt(arguments: [String: String]?) -> GetPrompt.Result {
    let url = arguments?["website_url"] ?? "{website_url}"
    let platformsStr = arguments?["platforms"] ?? "google_aio, chatgpt, perplexity, gemini, bing_copilot"

    let prompt = """
    Please evaluate the AI search platform readiness for \(url).

    Platforms to evaluate: \(platformsStr)

    **For each platform, check these signals:**

    **Google AI Overviews (google_aio):**
    - Schema.org markup present
    - E-E-A-T signals strong
    - Content matches "People Also Ask" patterns
    - Page speed and Core Web Vitals
    - Mobile optimization
    - Structured headings (H1→H2→H3)
    - FAQ schema present
    - Author expertise established
    - Internal linking strong
    - HTTPS with security headers

    **ChatGPT (chatgpt):**
    - GPTBot/OAI-SearchBot allowed in robots.txt
    - Content self-contained (low pronoun density)
    - Definition patterns present
    - Statistics and data points cited
    - Clear passage structure (134-167 words)
    - llms.txt present
    - Brand name used consistently (not pronouns)
    - Source attribution included
    - Page loads without JavaScript
    - Clean URL structure

    **Perplexity (perplexity):**
    - PerplexityBot allowed in robots.txt
    - Factual density high
    - Sources cited within content
    - Question-answer format used
    - Content freshness (recent dates)
    - Authority signals present
    - Topic expertise demonstrated
    - Data tables and structured data
    - Cross-referenced claims
    - Original research/insights

    **Use these tools for each platform:**
    1. `score_platform_readiness` with the platform name and checklist results
    2. Score each checklist item as true/false based on your analysis

    **Generate brand search URLs:**
    - Use `generate_platform_search_urls` with the brand name
    - Note which platforms already show the brand in results

    **Calculate brand authority:**
    - Use `calculate_brand_authority_score` with presence scores per platform

    **Final Report:**
    - Platform-by-platform readiness scores
    - Overall cross-platform readiness
    - Quick wins (items that improve multiple platform scores)
    - Platform-specific recommendations
    """

    return GetPrompt.Result(
        description: "Platform readiness check for \(url)",
        messages: [
            Prompt.Message.user(.text(text: prompt))
        ]
    )
}
