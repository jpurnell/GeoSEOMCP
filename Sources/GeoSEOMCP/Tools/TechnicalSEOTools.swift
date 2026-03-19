import Foundation
import SwiftMCPServer

/// Returns all technical SEO tools.
public func getTechnicalSEOTools() -> [any MCPToolHandler] {
    return [
        AnalyzeSecurityHeadersTool(),
        AnalyzeHeadingStructureTool(),
        AuditMetaTagsTool(),
        DetectSSRCapabilityTool(),
        ScoreTechnicalSEOTool(),
    ]
}

// MARK: - analyze_security_headers Tool

/// Analyze security headers against the 6 recommended headers.
public struct AnalyzeSecurityHeadersTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "analyze_security_headers",
        description: """
        Analyze HTTP security headers against recommended standards.

        Checks for 6 critical security headers (100 points total):
        - HSTS (20pts), CSP (20pts), X-Frame-Options (15pts),
        - X-Content-Type-Options (15pts), Referrer-Policy (15pts),
        - Permissions-Policy (15pts)
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "headers": MCPSchemaProperty(
                    type: "object",
                    description: "HTTP response headers as key-value pairs (lowercase keys)"
                ),
            ],
            required: ["headers"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("headers")
        }

        // Extract headers — require the argument exists
        guard let headersArg = args["headers"] else {
            throw ToolError.missingRequiredArgument("headers")
        }

        var headerDict: [String: String] = [:]
        if let dict = headersArg.value as? [String: AnyCodable] {
            for (k, v) in dict {
                headerDict[k.lowercased()] = "\(v.value)"
            }
        } else if let dict = headersArg.value as? [String: Any] {
            for (k, v) in dict {
                headerDict[k.lowercased()] = "\(v)"
            }
        }

        var totalScore = 0.0
        var found: [(String, Double)] = []
        var missing: [(String, Double)] = []

        for spec in SecurityHeaders.all {
            if headerDict[spec.headerKey] != nil {
                totalScore += spec.maxPoints
                found.append((spec.name, spec.maxPoints))
            } else {
                missing.append((spec.name, spec.maxPoints))
            }
        }

        var output = """
        Security Headers Analysis

        Score: \(String(format: "%.0f", totalScore)) / 100
        Headers Found: \(found.count) / \(SecurityHeaders.all.count)
        """

        if !found.isEmpty {
            output += "\n\nPresent:"
            for (name, points) in found {
                output += "\n  ✓ \(name) (+\(String(format: "%.0f", points)) pts)"
            }
        }

        if !missing.isEmpty {
            output += "\n\nMissing:"
            for (name, points) in missing {
                output += "\n  ✗ \(name) (\(String(format: "%.0f", points)) pts)"
            }
        }

        return .success(text: output)
    }
}

// MARK: - analyze_heading_structure Tool

/// Analyze HTML heading hierarchy for SEO compliance.
public struct AnalyzeHeadingStructureTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "analyze_heading_structure",
        description: """
        Analyze HTML heading structure for proper hierarchy.

        Checks for:
        - Single H1 tag (required)
        - Proper descending hierarchy (no skipped levels)
        - Heading count and distribution
        - Common SEO heading issues
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "headings": MCPSchemaProperty(
                    type: "array",
                    description: "Array of heading objects with 'level' (1-6) and 'text' properties",
                    items: MCPSchemaItems(type: "object")
                ),
            ],
            required: ["headings"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("headings")
        }

        guard let headingsArg = args["headings"] else {
            throw ToolError.missingRequiredArgument("headings")
        }

        struct Heading {
            let level: Int
            let text: String
        }

        var headings: [Heading] = []

        // AnyCodable wraps arrays as [AnyCodable] and objects as [String: AnyCodable]
        if let array = headingsArg.value as? [AnyCodable] {
            for item in array {
                if let dict = item.value as? [String: AnyCodable] {
                    let level: Int
                    if let intVal = dict["level"]?.value as? Int {
                        level = intVal
                    } else if let doubleVal = dict["level"]?.value as? Double {
                        level = Int(doubleVal)
                    } else {
                        level = 0
                    }
                    let text = (dict["text"]?.value as? String) ?? ""
                    if level > 0 { headings.append(Heading(level: level, text: text)) }
                }
            }
        }

        guard !headings.isEmpty else {
            throw ToolError.invalidArguments("headings must be an array of objects with 'level' and 'text'")
        }

        var issues: [String] = []

        // Check for single H1
        let h1Count = headings.filter { $0.level == 1 }.count
        if h1Count == 0 {
            issues.append("No H1 heading found — every page should have exactly one H1")
        } else if h1Count > 1 {
            issues.append("Multiple H1 headings found (\(h1Count)) — should have exactly one")
        }

        // Check for skipped levels
        for i in 1..<headings.count {
            let prev = headings[i - 1].level
            let curr = headings[i].level
            if curr > prev + 1 {
                issues.append("Skipped heading level: H\(prev) → H\(curr) (should not skip levels)")
            }
        }

        // Distribution
        var distribution: [Int: Int] = [:]
        for h in headings {
            distribution[h.level, default: 0] += 1
        }

        let isValid = issues.isEmpty

        var output = """
        Heading Structure Analysis

        Status: \(isValid ? "✓ Valid hierarchy" : "Issues found")
        Total Headings: \(headings.count)

        Distribution:
        """
        for level in 1...6 {
            let count = distribution[level] ?? 0
            if count > 0 {
                output += "\n  H\(level): \(count)"
            }
        }

        if !issues.isEmpty {
            output += "\n\nIssues:"
            for issue in issues { output += "\n  ✗ \(issue)" }
        }

        return .success(text: output)
    }
}

// MARK: - audit_meta_tags Tool

/// Audit essential meta tags for SEO.
public struct AuditMetaTagsTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "audit_meta_tags",
        description: """
        Audit essential meta tags for SEO compliance.

        Checks:
        - Title tag (present, length 30-60 chars)
        - Meta description (present, length 120-160 chars)
        - Canonical URL (present)
        - Robots meta (index/follow status)
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "title": MCPSchemaProperty(
                    type: "string",
                    description: "Page title tag content"
                ),
                "description": MCPSchemaProperty(
                    type: "string",
                    description: "Meta description content"
                ),
                "canonical": MCPSchemaProperty(
                    type: "string",
                    description: "Canonical URL"
                ),
                "robots": MCPSchemaProperty(
                    type: "string",
                    description: "Robots meta tag content"
                ),
            ],
            required: ["title"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("title")
        }

        let title = try args.getString("title")
        let description = args.getStringOptional("description")
        let canonical = args.getStringOptional("canonical")
        let robots = args.getStringOptional("robots")

        var issues: [String] = []
        var passes: [String] = []

        // Title check
        if title.isEmpty {
            issues.append("Title tag is empty or missing")
        } else if title.count < 30 {
            issues.append("Title too short (\(title.count) chars) — aim for 30-60")
        } else if title.count > 60 {
            issues.append("Title too long (\(title.count) chars) — aim for 30-60")
        } else {
            passes.append("Title length OK (\(title.count) chars)")
        }

        // Description check
        if let desc = description, !desc.isEmpty {
            if desc.count < 120 {
                issues.append("Description too short (\(desc.count) chars) — aim for 120-160")
            } else if desc.count > 160 {
                issues.append("Description too long (\(desc.count) chars) — aim for 120-160")
            } else {
                passes.append("Description length OK (\(desc.count) chars)")
            }
        } else {
            issues.append("Meta description is missing")
        }

        // Canonical check
        if let canon = canonical, !canon.isEmpty {
            passes.append("Canonical URL present")
        } else {
            issues.append("Canonical URL is missing")
        }

        // Robots check
        if let rob = robots, !rob.isEmpty {
            if rob.lowercased().contains("noindex") {
                issues.append("Robots tag contains 'noindex' — page will not be indexed")
            } else {
                passes.append("Robots meta allows indexing")
            }
        }

        var output = """
        Meta Tags Audit

        Title: \(title.isEmpty ? "(empty)" : title)
        Title Length: \(title.count) chars
        """

        if !passes.isEmpty {
            output += "\n\nPassing:"
            for pass in passes { output += "\n  ✓ \(pass)" }
        }
        if !issues.isEmpty {
            output += "\n\nIssues:"
            for issue in issues { output += "\n  ✗ \(issue)" }
        }

        return .success(text: output)
    }
}

// MARK: - detect_ssr_capability Tool

/// Detect server-side rendering capability.
public struct DetectSSRCapabilityTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "detect_ssr_capability",
        description: """
        Detect whether a page uses server-side rendering (SSR) or client-side rendering (CSR).

        SSR is critical for AI crawlers because most cannot execute JavaScript.
        Evaluates signals like initial HTML content presence, framework markers \
        (__NEXT_DATA__, __NUXT__), and content length.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "has_initial_content": MCPSchemaProperty(
                    type: "boolean",
                    description: "Whether the initial HTML contains substantial content"
                ),
                "has_next_data": MCPSchemaProperty(
                    type: "boolean",
                    description: "Whether __NEXT_DATA__ script is present (Next.js SSR)"
                ),
                "has_nuxt_data": MCPSchemaProperty(
                    type: "boolean",
                    description: "Whether __NUXT__ data is present (Nuxt.js SSR)"
                ),
                "content_length": MCPSchemaProperty(
                    type: "number",
                    description: "Length of initial HTML content in characters"
                ),
            ],
            required: ["has_initial_content"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("has_initial_content")
        }

        let hasContent = try args.getBool("has_initial_content")
        let hasNextData = args.getBoolOptional("has_next_data") ?? false
        let hasNuxtData = args.getBoolOptional("has_nuxt_data") ?? false
        let contentLength = args.getDoubleOptional("content_length") ?? 0

        var signals: [String] = []
        var score = 0.0

        if hasContent {
            signals.append("Initial HTML contains content")
            score += 40
        }
        if hasNextData {
            signals.append("Next.js SSR detected (__NEXT_DATA__)")
            score += 25
        }
        if hasNuxtData {
            signals.append("Nuxt.js SSR detected (__NUXT__)")
            score += 25
        }
        if contentLength > 2000 {
            signals.append("Substantial content length (\(Int(contentLength)) chars)")
            score += 10
        }

        let classification: String
        if score >= 40 {
            classification = "SSR (Server-Side Rendered)"
        } else {
            classification = "CSR (Client-Side Rendered)"
        }

        let impact: String
        if score >= 40 {
            impact = "Good — AI crawlers can access your content without JavaScript execution."
        } else {
            impact = "Warning — AI crawlers may not see your content. Consider implementing SSR or pre-rendering."
        }

        let output = """
        SSR Detection Analysis

        Classification: \(classification)
        Confidence Score: \(String(format: "%.0f", score)) / 100

        Signals Detected:
        \(signals.isEmpty ? "  None" : signals.map { "  • \($0)" }.joined(separator: "\n"))

        AI Crawler Impact: \(impact)
        """

        return .success(text: output)
    }
}

// MARK: - score_technical_seo Tool

/// Calculate weighted technical SEO composite score.
public struct ScoreTechnicalSEOTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "score_technical_seo",
        description: """
        Calculate a weighted technical SEO composite score.

        Weights (sum = 1.0):
        - SSR Capability: 25%
        - Meta Tags: 15%
        - Crawlability: 15%
        - Security Headers: 10%
        - Core Web Vitals: 10%
        - Mobile Optimization: 10%
        - URL Structure: 5%
        - Server Response: 5%
        - Additional Technical: 5%

        Each component should be a score from 0-100.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "ssr_score": MCPSchemaProperty(type: "number", description: "SSR capability score (0-100)"),
                "meta_tags_score": MCPSchemaProperty(type: "number", description: "Meta tags audit score (0-100)"),
                "crawlability_score": MCPSchemaProperty(type: "number", description: "Crawlability score (0-100)"),
                "security_score": MCPSchemaProperty(type: "number", description: "Security headers score (0-100)"),
                "core_web_vitals_score": MCPSchemaProperty(type: "number", description: "Core Web Vitals score (0-100)"),
                "mobile_score": MCPSchemaProperty(type: "number", description: "Mobile optimization score (0-100)"),
                "url_score": MCPSchemaProperty(type: "number", description: "URL structure score (0-100)"),
                "server_response_score": MCPSchemaProperty(type: "number", description: "Server response score (0-100)"),
            ],
            required: ["ssr_score", "meta_tags_score", "crawlability_score", "security_score",
                        "core_web_vitals_score", "mobile_score", "url_score", "server_response_score"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("ssr_score")
        }

        let ssr = try args.getDouble("ssr_score")
        let meta = try args.getDouble("meta_tags_score")
        let crawl = try args.getDouble("crawlability_score")
        let security = try args.getDouble("security_score")
        let cwv = try args.getDouble("core_web_vitals_score")
        let mobile = try args.getDouble("mobile_score")
        let url = try args.getDouble("url_score")
        let server = try args.getDouble("server_response_score")

        let composite = ssr * GEOWeights.ssrCapability
            + meta * GEOWeights.metaTags
            + crawl * GEOWeights.crawlability
            + security * GEOWeights.securityHeaders
            + cwv * GEOWeights.coreWebVitals
            + mobile * GEOWeights.mobileOptimization
            + url * GEOWeights.urlStructure
            + server * GEOWeights.serverResponse

        let output = """
        Technical SEO Composite Score

        Overall Score: \(String(format: "%.1f", composite)) / 100

        Component Breakdown:
          SSR Capability (25%):     \(String(format: "%.0f", ssr))
          Meta Tags (15%):          \(String(format: "%.0f", meta))
          Crawlability (15%):       \(String(format: "%.0f", crawl))
          Security Headers (10%):   \(String(format: "%.0f", security))
          Core Web Vitals (10%):    \(String(format: "%.0f", cwv))
          Mobile Optimization (10%): \(String(format: "%.0f", mobile))
          URL Structure (5%):       \(String(format: "%.0f", url))
          Server Response (5%):     \(String(format: "%.0f", server))
        """

        return .success(text: output)
    }
}
