import Foundation
import SwiftMCPServer

/// Returns all brand authority and platform readiness tools.
public func getBrandPlatformTools() -> [any MCPToolHandler] {
    return [
        CalculateBrandAuthorityScoreTool(),
        ScorePlatformPresenceTool(),
        GeneratePlatformSearchUrlsTool(),
        ScorePlatformReadinessTool(),
    ]
}

// MARK: - calculate_brand_authority_score Tool

/// Calculate weighted brand authority score from platform scores.
public struct CalculateBrandAuthorityScoreTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "calculate_brand_authority_score",
        description: """
        Calculate a weighted brand authority score from platform presence scores.

        Weights:
        - YouTube (25%): Video content authority
        - Reddit (25%): Community presence and discussion
        - Wikipedia (20%): Knowledge base presence
        - LinkedIn (15%): Professional authority
        - Other Platforms (15%): Additional platform presence

        Each platform score should be 0-100.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "youtube_score": MCPSchemaProperty(type: "number", description: "YouTube presence score (0-100)"),
                "reddit_score": MCPSchemaProperty(type: "number", description: "Reddit presence score (0-100)"),
                "wikipedia_score": MCPSchemaProperty(type: "number", description: "Wikipedia presence score (0-100)"),
                "linkedin_score": MCPSchemaProperty(type: "number", description: "LinkedIn presence score (0-100)"),
                "other_platforms_score": MCPSchemaProperty(type: "number", description: "Other platforms score (0-100)"),
            ],
            required: ["youtube_score", "reddit_score", "wikipedia_score", "linkedin_score", "other_platforms_score"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("youtube_score")
        }

        let youtube = try args.getDouble("youtube_score")
        let reddit = try args.getDouble("reddit_score")
        let wikipedia = try args.getDouble("wikipedia_score")
        let linkedin = try args.getDouble("linkedin_score")
        let other = try args.getDouble("other_platforms_score")

        let composite = youtube * GEOWeights.youtube
            + reddit * GEOWeights.reddit
            + wikipedia * GEOWeights.wikipedia
            + linkedin * GEOWeights.linkedin
            + other * GEOWeights.otherPlatforms

        let output = """
        Brand Authority Score

        Composite Score: \(String(format: "%.1f", composite)) / 100

        Platform Breakdown:
          YouTube (25%):          \(String(format: "%.0f", youtube))
          Reddit (25%):           \(String(format: "%.0f", reddit))
          Wikipedia (20%):        \(String(format: "%.0f", wikipedia))
          LinkedIn (15%):         \(String(format: "%.0f", linkedin))
          Other Platforms (15%):  \(String(format: "%.0f", other))
        """

        return .success(text: output)
    }
}

// MARK: - score_platform_presence Tool

/// Score presence on a specific platform.
public struct ScorePlatformPresenceTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "score_platform_presence",
        description: """
        Score brand presence on a specific platform.

        Evaluates:
        - Whether the brand has a presence
        - Follower/subscriber count
        - Engagement rate
        - Posting frequency
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "platform": MCPSchemaProperty(type: "string", description: "Platform name (youtube, reddit, wikipedia, linkedin, twitter, facebook)"),
                "has_presence": MCPSchemaProperty(type: "boolean", description: "Whether the brand has an active presence"),
                "follower_count": MCPSchemaProperty(type: "number", description: "Number of followers/subscribers"),
                "engagement_rate": MCPSchemaProperty(type: "number", description: "Engagement rate percentage"),
                "post_frequency": MCPSchemaProperty(type: "string", description: "Posting frequency: daily, weekly, monthly, rarely"),
            ],
            required: ["platform", "has_presence"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("platform")
        }

        let platform = try args.getString("platform")
        let hasPresence = try args.getBool("has_presence")

        guard hasPresence else {
            return .success(text: """
            Platform Presence: \(platform)

            Status: No presence detected
            Score: 0 / 100

            Recommendation: Establish a presence on \(platform) to improve brand authority.
            """)
        }

        let followers = args.getDoubleOptional("follower_count") ?? 0
        let engagement = args.getDoubleOptional("engagement_rate") ?? 0
        let frequency = args.getStringOptional("post_frequency") ?? "unknown"

        // Score components
        var score = 20.0 // Base for having presence

        // Followers score (up to 30 pts)
        if followers >= 100_000 { score += 30 }
        else if followers >= 10_000 { score += 20 }
        else if followers >= 1_000 { score += 10 }
        else if followers > 0 { score += 5 }

        // Engagement score (up to 25 pts)
        if engagement >= 5.0 { score += 25 }
        else if engagement >= 2.0 { score += 15 }
        else if engagement >= 0.5 { score += 10 }
        else if engagement > 0 { score += 5 }

        // Frequency score (up to 25 pts)
        switch frequency.lowercased() {
        case "daily": score += 25
        case "weekly": score += 20
        case "monthly": score += 10
        case "rarely": score += 5
        default: break
        }

        score = min(score, 100)

        let output = """
        Platform Presence: \(platform)

        Score: \(String(format: "%.0f", score)) / 100

        Metrics:
          Has Presence: Yes
          Followers: \(followers >= 1 ? String(format: "%.0f", followers) : "N/A")
          Engagement Rate: \(engagement > 0 ? String(format: "%.1f%%", engagement) : "N/A")
          Post Frequency: \(frequency)
        """

        return .success(text: output)
    }
}

// MARK: - generate_platform_search_urls Tool

/// Generate search URLs for brand verification across platforms.
public struct GeneratePlatformSearchUrlsTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "generate_platform_search_urls",
        description: """
        Generate search URLs for verifying brand presence across platforms.

        Creates URL-encoded search links for:
        YouTube, Reddit, Wikipedia, LinkedIn, Twitter/X, Facebook, GitHub, Crunchbase

        Use these URLs to manually verify brand presence on each platform.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "brand_name": MCPSchemaProperty(type: "string", description: "Brand or company name to search for"),
            ],
            required: ["brand_name"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("brand_name")
        }

        let brand = try args.getString("brand_name")
        let encoded = brand.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? brand

        let output = """
        Brand Search URLs: \(brand)

        YouTube: https://www.youtube.com/results?search_query=\(encoded)
        Reddit: https://www.reddit.com/search/?q=\(encoded)
        Wikipedia: https://en.wikipedia.org/w/index.php?search=\(encoded)
        LinkedIn: https://www.linkedin.com/search/results/companies/?keywords=\(encoded)
        Twitter/X: https://twitter.com/search?q=\(encoded)
        Facebook: https://www.facebook.com/search/pages/?q=\(encoded)
        GitHub: https://github.com/search?q=\(encoded)
        Crunchbase: https://www.crunchbase.com/textsearch?q=\(encoded)

        Use these URLs to verify brand presence on each platform.
        """

        return .success(text: output)
    }
}

// MARK: - score_platform_readiness Tool

/// Score platform readiness based on a checklist.
public struct ScorePlatformReadinessTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "score_platform_readiness",
        description: """
        Score platform readiness for a specific AI search platform.

        Evaluates a checklist of readiness items for:
        - google_aio: Google AI Overviews readiness
        - chatgpt: ChatGPT search readiness
        - perplexity: Perplexity readiness
        - gemini: Gemini readiness
        - bing_copilot: Bing Copilot readiness

        Pass an array of boolean values for each checklist item.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "platform": MCPSchemaProperty(type: "string", description: "AI platform: google_aio, chatgpt, perplexity, gemini, bing_copilot"),
                "checklist_items": MCPSchemaProperty(
                    type: "array",
                    description: "Array of boolean values for each readiness checklist item",
                    items: MCPSchemaItems(type: "boolean")
                ),
            ],
            required: ["platform", "checklist_items"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("platform")
        }

        let platform = try args.getString("platform")

        // Parse checklist from AnyCodable array
        guard let checklistArg = args["checklist_items"],
              let checklistArray = checklistArg.value as? [AnyCodable]
        else {
            throw ToolError.invalidArguments("checklist_items must be an array of booleans")
        }

        let checklist = checklistArray.map { ($0.value as? Bool) ?? false }
        let passed = checklist.filter { $0 }.count
        let total = checklist.count
        let score = total > 0 ? (Double(passed) / Double(total)) * 100.0 : 0.0

        let platformName: String
        switch platform.lowercased() {
        case "google_aio": platformName = "Google AI Overviews"
        case "chatgpt": platformName = "ChatGPT Search"
        case "perplexity": platformName = "Perplexity"
        case "gemini": platformName = "Gemini"
        case "bing_copilot": platformName = "Bing Copilot"
        default: platformName = platform
        }

        let output = """
        Platform Readiness: \(platformName)

        Score: \(String(format: "%.0f", score)) / 100
        Items Passed: \(passed) / \(total)

        \(score >= 80 ? "Excellent readiness for \(platformName)." :
          score >= 60 ? "Good readiness with room for improvement." :
          score >= 40 ? "Moderate readiness — several items need attention." :
          "Low readiness — significant work needed for \(platformName) optimization.")
        """

        return .success(text: output)
    }
}
