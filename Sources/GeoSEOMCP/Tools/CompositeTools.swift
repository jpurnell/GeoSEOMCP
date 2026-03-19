import Foundation
import SwiftMCPServer

/// Returns all composite scoring tools.
public func getCompositeTools() -> [any MCPToolHandler] {
    return [
        CalculateGEOCompositeScoreTool(),
        ClassifyAuditFindingsTool(),
        DetectBusinessTypeTool(),
    ]
}

// MARK: - calculate_geo_composite_score Tool

/// Calculate the overall GEO composite score from all category scores.
public struct CalculateGEOCompositeScoreTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "calculate_geo_composite_score",
        description: """
        Calculate the overall GEO (Generative Engine Optimization) composite score.

        Weights:
        - Citability (25%): How well content is structured for AI citation
        - Brand Authority (20%): Platform presence and brand signals
        - E-E-A-T (20%): Experience, Expertise, Authoritativeness, Trustworthiness
        - Technical SEO (15%): Server-side rendering, security, meta tags
        - Schema (10%): Structured data completeness
        - Platform Readiness (10%): AI platform-specific optimization

        Each component score should be 0-100.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "citability_score": MCPSchemaProperty(type: "number", description: "Citability score (0-100)"),
                "brand_authority_score": MCPSchemaProperty(type: "number", description: "Brand authority score (0-100)"),
                "eeat_score": MCPSchemaProperty(type: "number", description: "E-E-A-T score (0-100)"),
                "technical_score": MCPSchemaProperty(type: "number", description: "Technical SEO score (0-100)"),
                "schema_score": MCPSchemaProperty(type: "number", description: "Schema completeness score (0-100)"),
                "platform_score": MCPSchemaProperty(type: "number", description: "Platform readiness score (0-100)"),
            ],
            required: ["citability_score", "brand_authority_score", "eeat_score",
                        "technical_score", "schema_score", "platform_score"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("citability_score")
        }

        let citability = try args.getDouble("citability_score")
        let brand = try args.getDouble("brand_authority_score")
        let eeat = try args.getDouble("eeat_score")
        let technical = try args.getDouble("technical_score")
        let schema = try args.getDouble("schema_score")
        let platform = try args.getDouble("platform_score")

        let composite = citability * GEOWeights.citability
            + brand * GEOWeights.brandAuthority
            + eeat * GEOWeights.contentEEAT
            + technical * GEOWeights.technical
            + schema * GEOWeights.schema
            + platform * GEOWeights.platform

        let grade: String
        if composite >= 80 { grade = "A — Excellent GEO optimization" }
        else if composite >= 65 { grade = "B — Good with room for improvement" }
        else if composite >= 50 { grade = "C — Average, needs work" }
        else if composite >= 35 { grade = "D — Below average" }
        else { grade = "F — Significant optimization needed" }

        let output = """
        GEO Composite Score

        Overall Score: \(String(format: "%.1f", composite)) / 100
        Grade: \(grade)

        Category Breakdown:
          Citability (25%):        \(String(format: "%.1f", citability))
          Brand Authority (20%):   \(String(format: "%.1f", brand))
          E-E-A-T (20%):           \(String(format: "%.1f", eeat))
          Technical SEO (15%):     \(String(format: "%.1f", technical))
          Schema (10%):            \(String(format: "%.1f", schema))
          Platform Readiness (10%): \(String(format: "%.1f", platform))
        """

        return .success(text: output)
    }
}

// MARK: - classify_audit_findings Tool

/// Classify audit findings by priority based on score gaps.
public struct ClassifyAuditFindingsTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "classify_audit_findings",
        description: """
        Classify GEO audit findings by priority based on score gaps.

        Priority levels:
        - Critical (gap ≥ 25): Immediate action required
        - High (gap 12-24): Should address soon
        - Medium (gap 6-11): Worth improving
        - Low (gap < 6): Minor optimization

        Provide findings as an array of objects with area, current_score, and target_score.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "findings": MCPSchemaProperty(
                    type: "array",
                    description: "Array of finding objects with 'area', 'current_score', and 'target_score'",
                    items: MCPSchemaItems(type: "object")
                ),
            ],
            required: ["findings"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("findings")
        }

        guard let findingsArg = args["findings"],
              let findingsArray = findingsArg.value as? [AnyCodable]
        else {
            throw ToolError.invalidArguments("findings must be an array of objects")
        }

        struct Finding {
            let area: String
            let currentScore: Double
            let targetScore: Double
            let gap: Double
            let priority: String
        }

        var findings: [Finding] = []

        for item in findingsArray {
            if let dict = item.value as? [String: AnyCodable] {
                let area = (dict["area"]?.value as? String) ?? "Unknown"
                let current = (dict["current_score"]?.value as? Double)
                    ?? (dict["current_score"]?.value as? Int).map { Double($0) } ?? 0
                let target = (dict["target_score"]?.value as? Double)
                    ?? (dict["target_score"]?.value as? Int).map { Double($0) } ?? 100

                let gap = target - current
                let priority: String
                if gap >= 25 { priority = "Critical" }
                else if gap >= 12 { priority = "High" }
                else if gap >= 6 { priority = "Medium" }
                else { priority = "Low" }

                findings.append(Finding(
                    area: area, currentScore: current,
                    targetScore: target, gap: gap, priority: priority
                ))
            }
        }

        // Sort by gap descending
        findings.sort { $0.gap > $1.gap }

        let critical = findings.filter { $0.priority == "Critical" }
        let high = findings.filter { $0.priority == "High" }
        let medium = findings.filter { $0.priority == "Medium" }
        let low = findings.filter { $0.priority == "Low" }

        var output = """
        Audit Findings Classification

        Total Findings: \(findings.count)
        Critical: \(critical.count) | High: \(high.count) | Medium: \(medium.count) | Low: \(low.count)
        """

        for finding in findings {
            output += "\n\n[\(finding.priority.uppercased())] \(finding.area)"
            output += "\n  Current: \(String(format: "%.0f", finding.currentScore)) → Target: \(String(format: "%.0f", finding.targetScore)) (gap: \(String(format: "%.0f", finding.gap)))"
        }

        return .success(text: output)
    }
}

// MARK: - detect_business_type Tool

/// Detect business type from page signals.
public struct DetectBusinessTypeTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "detect_business_type",
        description: """
        Detect business type from page signals to customize GEO recommendations.

        Analyzes signals like:
        - SaaS: pricing_page, signup_cta, api_docs, free_trial, dashboard
        - E-commerce: product_catalog, shopping_cart, checkout, product_reviews
        - Local Business: physical_address, google_maps, phone_number, opening_hours
        - Media/Publisher: article_feed, author_pages, categories, rss_feed
        - Agency/Consulting: case_studies, client_logos, team_page, services

        Returns the detected business type and confidence level.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "signals": MCPSchemaProperty(
                    type: "array",
                    description: "Array of detected signal strings from the website",
                    items: MCPSchemaItems(type: "string")
                ),
            ],
            required: ["signals"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("signals")
        }

        let signals = try args.getStringArray("signals")
        let signalSet = Set(signals.map { $0.lowercased() })

        let businessTypes: [(String, [String], String)] = [
            ("SaaS", ["pricing_page", "signup_cta", "api_docs", "free_trial", "dashboard", "saas", "subscription"], "Software as a Service"),
            ("E-commerce", ["product_catalog", "shopping_cart", "checkout", "product_reviews", "add_to_cart", "ecommerce"], "Online Retail"),
            ("Local Business", ["physical_address", "google_maps", "phone_number", "opening_hours", "directions", "local"], "Local/Physical Business"),
            ("Media/Publisher", ["article_feed", "author_pages", "categories", "rss_feed", "editorial", "news"], "Content Publisher"),
            ("Agency/Consulting", ["case_studies", "client_logos", "team_page", "services", "portfolio", "consulting"], "Professional Services"),
        ]

        var matches: [(String, Int, String)] = []

        for (typeName, typeSignals, description) in businessTypes {
            let matchCount = typeSignals.filter { signalSet.contains($0) }.count
            if matchCount > 0 {
                matches.append((typeName, matchCount, description))
            }
        }

        matches.sort { $0.1 > $1.1 }

        let detected = matches.first
        let confidence: String
        if let best = detected {
            if best.1 >= 4 { confidence = "High" }
            else if best.1 >= 2 { confidence = "Medium" }
            else { confidence = "Low" }
        } else {
            confidence = "None"
        }

        var output = """
        Business Type Detection

        Detected Type: \(detected?.0 ?? "Unknown")
        Description: \(detected?.2 ?? "Could not determine business type")
        Confidence: \(confidence)
        Signals Analyzed: \(signals.count)
        """

        if !matches.isEmpty {
            output += "\n\nType Matches:"
            for (name, count, _) in matches {
                output += "\n  \(name): \(count) signal(s)"
            }
        }

        return .success(text: output)
    }
}
