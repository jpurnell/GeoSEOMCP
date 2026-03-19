import Foundation
import SwiftMCPServer

/// Returns all crawler access analysis tools.
public func getCrawlerAccessTools() -> [any MCPToolHandler] {
    return [
        ParseRobotsTxtTool(),
        AnalyzeAICrawlerAccessTool(),
        CalculateAIVisibilityScoreTool(),
    ]
}

// MARK: - Robots.txt Parsing

/// A single directive in a robots.txt rule group.
public struct RobotsTxtDirective: Sendable {
    public let type: DirectiveType
    public let path: String

    public enum DirectiveType: String, Sendable {
        case allow = "Allow"
        case disallow = "Disallow"
    }
}

/// Parse robots.txt content into a dictionary of user-agent → directives.
public func parseRobotsTxt(_ content: String) -> [String: [RobotsTxtDirective]] {
    guard !content.isEmpty else { return [:] }

    var result: [String: [RobotsTxtDirective]] = [:]
    var currentAgents: [String] = []

    for line in content.components(separatedBy: .newlines) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Skip comments and empty lines
        if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

        let parts = trimmed.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { continue }

        let key = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
        let value = parts[1].trimmingCharacters(in: .whitespaces)

        switch key {
        case "user-agent":
            // If we have a new user-agent after directives, start fresh
            if !currentAgents.isEmpty && result[currentAgents[0]] != nil {
                currentAgents = [value]
            } else {
                currentAgents.append(value)
            }
            // Initialize if needed
            for agent in currentAgents {
                if result[agent] == nil {
                    result[agent] = []
                }
            }
        case "allow":
            let directive = RobotsTxtDirective(type: .allow, path: value)
            for agent in currentAgents {
                result[agent, default: []].append(directive)
            }
        case "disallow":
            let directive = RobotsTxtDirective(type: .disallow, path: value)
            for agent in currentAgents {
                result[agent, default: []].append(directive)
            }
        default:
            break // Ignore Crawl-delay, Sitemap, etc.
        }
    }

    return result
}

// MARK: - AI Crawler Access Analysis

/// Access status for a single AI crawler.
public struct CrawlerAccessResult: Sendable {
    public let crawlerName: String
    public let userAgent: String
    public let tier: CrawlerTier
    public let status: AccessStatus
    public let reason: String

    public enum AccessStatus: String, Sendable {
        case allowed = "Allowed"
        case blocked = "Blocked"
        case partiallyRestricted = "Partially Restricted"
    }
}

/// Analyze which of the 14 AI crawlers are allowed/blocked by robots.txt rules.
public func analyzeAICrawlerAccess(rules: [String: [RobotsTxtDirective]]) -> [CrawlerAccessResult] {
    return AICrawlerRegistry.allCrawlers.map { crawler in
        // Check for specific user-agent rules first, then fall back to wildcard
        let specificRules = rules[crawler.userAgent]
        let wildcardRules = rules["*"]

        let activeRules: [RobotsTxtDirective]?
        let ruleSource: String

        if let specific = specificRules {
            activeRules = specific
            ruleSource = "specific user-agent rule"
        } else if let wildcard = wildcardRules {
            activeRules = wildcard
            ruleSource = "wildcard (*) rule"
        } else {
            // No rules at all = allowed
            return CrawlerAccessResult(
                crawlerName: crawler.name,
                userAgent: crawler.userAgent,
                tier: crawler.tier,
                status: .allowed,
                reason: "No robots.txt rules found — allowed by default"
            )
        }

        guard let directives = activeRules, !directives.isEmpty else {
            return CrawlerAccessResult(
                crawlerName: crawler.name,
                userAgent: crawler.userAgent,
                tier: crawler.tier,
                status: .allowed,
                reason: "No directives specified — allowed by default"
            )
        }

        // Check for blanket disallow
        let hasBlanketDisallow = directives.contains { $0.type == .disallow && $0.path == "/" }
        let hasBlanketAllow = directives.contains { $0.type == .allow && $0.path == "/" }
        let hasPartialDisallow = directives.contains { $0.type == .disallow && $0.path != "/" && !$0.path.isEmpty }

        if hasBlanketDisallow && !hasBlanketAllow {
            return CrawlerAccessResult(
                crawlerName: crawler.name,
                userAgent: crawler.userAgent,
                tier: crawler.tier,
                status: .blocked,
                reason: "Blocked by \(ruleSource): Disallow: /"
            )
        } else if hasPartialDisallow && !hasBlanketDisallow {
            return CrawlerAccessResult(
                crawlerName: crawler.name,
                userAgent: crawler.userAgent,
                tier: crawler.tier,
                status: .partiallyRestricted,
                reason: "Partially restricted by \(ruleSource)"
            )
        } else {
            return CrawlerAccessResult(
                crawlerName: crawler.name,
                userAgent: crawler.userAgent,
                tier: crawler.tier,
                status: .allowed,
                reason: "Allowed by \(ruleSource)"
            )
        }
    }
}

// MARK: - AI Visibility Score

/// Calculate AI visibility score (0-100) based on crawler access and AI files.
public func calculateAIVisibilityScore(
    access: [CrawlerAccessResult],
    hasLlmsTxt: Bool,
    hasAiTxt: Bool
) -> Double {
    // Tier 1 score: each allowed crawler = 20 points (5 crawlers × 20 = 100 max)
    let tier1 = access.filter { $0.tier == .tier1 }
    let tier1Allowed = Double(tier1.filter { $0.status == .allowed }.count)
    let tier1Score = (tier1Allowed / 5.0) * 100.0

    // Tier 2 score: each allowed crawler = 20 points (5 crawlers × 20 = 100 max)
    let tier2 = access.filter { $0.tier == .tier2 }
    let tier2Allowed = Double(tier2.filter { $0.status == .allowed }.count)
    let tier2Score = (tier2Allowed / 5.0) * 100.0

    // No blanket blocks: 100 if no crawler is fully blocked, scaled down otherwise
    let totalBlocked = Double(access.filter { $0.status == .blocked }.count)
    let noBlanketScore = max(0.0, 100.0 - (totalBlocked / 14.0) * 100.0)

    // AI files bonus
    var aiFilesScore = 0.0
    if hasLlmsTxt { aiFilesScore += 50.0 }
    if hasAiTxt { aiFilesScore += 50.0 }

    // Weighted composite
    let composite = tier1Score * GEOWeights.tier1Access
        + tier2Score * GEOWeights.tier2Access
        + noBlanketScore * GEOWeights.noBlanketBlocks
        + aiFilesScore * GEOWeights.aiFiles

    return min(composite, 100.0)
}

// MARK: - parse_robots_txt Tool

/// Parse robots.txt content and extract user-agent rules.
public struct ParseRobotsTxtTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "parse_robots_txt",
        description: """
        Parse robots.txt content and extract user-agent rules.

        Parses standard robots.txt format with User-agent, Allow, and Disallow \
        directives. Returns structured data about which paths are allowed or \
        disallowed for each user-agent. Comments and blank lines are handled correctly.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "content": MCPSchemaProperty(
                    type: "string",
                    description: "The raw robots.txt file content to parse"
                ),
            ],
            required: ["content"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("content")
        }

        let content = try args.getString("content")
        let rules = parseRobotsTxt(content)

        if rules.isEmpty {
            return .success(text: "Robots.txt Parsing Result\n\nNo rules found. All crawlers are allowed by default.")
        }

        var output = "Robots.txt Parsing Result\n\nUser-Agent Groups: \(rules.count)\n"

        for (agent, directives) in rules.sorted(by: { $0.key < $1.key }) {
            output += "\nUser-agent: \(agent)"
            for directive in directives {
                output += "\n  \(directive.type.rawValue): \(directive.path)"
            }
        }

        return .success(text: output)
    }
}

// MARK: - analyze_ai_crawler_access Tool

/// Analyze which AI crawlers are allowed/blocked by robots.txt.
public struct AnalyzeAICrawlerAccessTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "analyze_ai_crawler_access",
        description: """
        Analyze which of the 14 AI crawlers are allowed or blocked by robots.txt rules.

        Evaluates access for all AI crawlers across 3 tiers:
        - Tier 1 (Critical): GPTBot, OAI-SearchBot, ChatGPT-User, ClaudeBot, PerplexityBot
        - Tier 2 (Important): Google-Extended, GoogleOther, Applebot-Extended, Amazonbot, FacebookBot
        - Tier 3 (Training): CCBot, anthropic-ai, Bytespider, cohere-ai

        Reports per-crawler status (Allowed/Blocked/Partially Restricted) with reasons.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "robots_txt": MCPSchemaProperty(
                    type: "string",
                    description: "The raw robots.txt content"
                ),
            ],
            required: ["robots_txt"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("robots_txt")
        }

        let robotsTxt = try args.getString("robots_txt")
        let rules = parseRobotsTxt(robotsTxt)
        let access = analyzeAICrawlerAccess(rules: rules)

        var output = "AI Crawler Access Analysis\n"

        for tier in CrawlerTier.allCases {
            let tierCrawlers = access.filter { $0.tier == tier }
            let allowed = tierCrawlers.filter { $0.status == .allowed }.count
            let blocked = tierCrawlers.filter { $0.status == .blocked }.count

            output += "\nTier \(tier.rawValue) — \(allowed) allowed, \(blocked) blocked:"
            for crawler in tierCrawlers {
                output += "\n  \(crawler.crawlerName): \(crawler.status.rawValue) — \(crawler.reason)"
            }
        }

        let totalAllowed = access.filter { $0.status == .allowed }.count
        let totalBlocked = access.filter { $0.status == .blocked }.count
        output += "\n\nSummary: \(totalAllowed)/14 allowed, \(totalBlocked)/14 blocked"

        return .success(text: output)
    }
}

// MARK: - calculate_ai_visibility_score Tool

/// Calculate weighted AI visibility score based on crawler access.
public struct CalculateAIVisibilityScoreTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "calculate_ai_visibility_score",
        description: """
        Calculate a weighted AI visibility score (0-100) based on crawler access.

        Scoring weights:
        - Tier 1 access (50%): Critical crawlers for AI search visibility
        - Tier 2 access (25%): Broader AI ecosystem crawlers
        - No blanket blocks (15%): Penalty for blanket blocking
        - AI-specific files (10%): Bonus for llms.txt and ai.txt

        Provide robots.txt content and indicate whether llms.txt/ai.txt files exist.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "robots_txt": MCPSchemaProperty(
                    type: "string",
                    description: "The raw robots.txt content"
                ),
                "has_llms_txt": MCPSchemaProperty(
                    type: "boolean",
                    description: "Whether the site has an llms.txt file"
                ),
                "has_ai_txt": MCPSchemaProperty(
                    type: "boolean",
                    description: "Whether the site has an ai.txt file"
                ),
            ],
            required: ["robots_txt"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("robots_txt")
        }

        let robotsTxt = try args.getString("robots_txt")
        let hasLlmsTxt = args.getBoolOptional("has_llms_txt") ?? false
        let hasAiTxt = args.getBoolOptional("has_ai_txt") ?? false

        let rules = parseRobotsTxt(robotsTxt)
        let access = analyzeAICrawlerAccess(rules: rules)
        let score = calculateAIVisibilityScore(access: access, hasLlmsTxt: hasLlmsTxt, hasAiTxt: hasAiTxt)

        let tier1Allowed = access.filter { $0.tier == .tier1 && $0.status == .allowed }.count
        let tier2Allowed = access.filter { $0.tier == .tier2 && $0.status == .allowed }.count

        let output = """
        AI Visibility Score: \(String(format: "%.1f", score)) / 100

        Component Breakdown:
          Tier 1 Access (50%): \(tier1Allowed)/5 crawlers allowed
          Tier 2 Access (25%): \(tier2Allowed)/5 crawlers allowed
          No Blanket Blocks (15%): \(access.filter { $0.status == .blocked }.count == 0 ? "Pass" : "\(access.filter { $0.status == .blocked }.count) blocked")
          AI Files (10%): llms.txt \(hasLlmsTxt ? "✓" : "✗"), ai.txt \(hasAiTxt ? "✓" : "✗")

        \(score >= 80 ? "Excellent AI visibility." :
          score >= 60 ? "Good AI visibility with room for improvement." :
          score >= 40 ? "Moderate AI visibility — consider allowing more AI crawlers." :
          "Poor AI visibility — most AI crawlers are blocked.")
        """

        return .success(text: output)
    }
}
