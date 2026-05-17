import Foundation

// MARK: - AI Crawler Registry

/// An AI crawler definition with its user-agent string, owner, tier, and access recommendation.
public struct AICrawler: Sendable {
    /// Crawler display name.
    public let name: String
    /// User-agent string used in HTTP requests.
    public let userAgent: String
    /// Organization operating the crawler.
    public let owner: String
    /// Description of crawler's purpose.
    public let purpose: String
    /// Importance tier classification.
    public let tier: CrawlerTier
    /// Recommended robots.txt action.
    public let recommendation: CrawlerRecommendation
}

/// Classification of AI crawlers by importance for AI search visibility.
public enum CrawlerTier: Int, Sendable, CaseIterable {
    /// Critical for AI search visibility — ALLOW these.
    case tier1 = 1
    /// Important for broader AI ecosystem — ALLOW these.
    case tier2 = 2
    /// Training-only crawlers — context-dependent decision.
    case tier3 = 3
}

/// Recommended action for a crawler in robots.txt.
public enum CrawlerRecommendation: String, Sendable {
    case allow = "ALLOW"
    case block = "BLOCK" // LIVE: returned in MCP tool responses for client consumption
    case contextDependent = "CONTEXT_DEPENDENT"
}

/// Registry of 14 AI crawlers across 3 tiers.
public enum AICrawlerRegistry {

    // MARK: Tier 1 — Critical for AI Search

    /// Tier 1 crawlers critical for AI search visibility.
    public static let tier1Crawlers: [AICrawler] = [
        AICrawler(
            name: "GPTBot",
            userAgent: "GPTBot",
            owner: "OpenAI",
            purpose: "Training data for GPT models",
            tier: .tier1,
            recommendation: .allow
        ),
        AICrawler(
            name: "OAI-SearchBot",
            userAgent: "OAI-SearchBot",
            owner: "OpenAI",
            purpose: "ChatGPT search results",
            tier: .tier1,
            recommendation: .allow
        ),
        AICrawler(
            name: "ChatGPT-User",
            userAgent: "ChatGPT-User",
            owner: "OpenAI",
            purpose: "Real-time browsing for ChatGPT",
            tier: .tier1,
            recommendation: .allow
        ),
        AICrawler(
            name: "ClaudeBot",
            userAgent: "ClaudeBot",
            owner: "Anthropic",
            purpose: "Training and search for Claude",
            tier: .tier1,
            recommendation: .allow
        ),
        AICrawler(
            name: "PerplexityBot",
            userAgent: "PerplexityBot",
            owner: "Perplexity AI",
            purpose: "Perplexity search engine",
            tier: .tier1,
            recommendation: .allow
        ),
    ]

    // MARK: Tier 2 — Broader AI Ecosystem

    /// Tier 2 crawlers important for broader AI ecosystem.
    public static let tier2Crawlers: [AICrawler] = [
        AICrawler(
            name: "Google-Extended",
            userAgent: "Google-Extended",
            owner: "Google",
            purpose: "Gemini and AI Overviews training",
            tier: .tier2,
            recommendation: .allow
        ),
        AICrawler(
            name: "GoogleOther",
            userAgent: "GoogleOther",
            owner: "Google",
            purpose: "Google R&D and AI projects",
            tier: .tier2,
            recommendation: .allow
        ),
        AICrawler(
            name: "Applebot-Extended",
            userAgent: "Applebot-Extended",
            owner: "Apple",
            purpose: "Apple Intelligence and Siri",
            tier: .tier2,
            recommendation: .allow
        ),
        AICrawler(
            name: "Amazonbot",
            userAgent: "Amazonbot",
            owner: "Amazon",
            purpose: "Alexa and Amazon AI services",
            tier: .tier2,
            recommendation: .allow
        ),
        AICrawler(
            name: "FacebookBot",
            userAgent: "FacebookBot",
            owner: "Meta",
            purpose: "Meta AI training and features",
            tier: .tier2,
            recommendation: .allow
        ),
    ]

    // MARK: Tier 3 — Training-Only (Context-Dependent)

    /// Tier 3 training-only crawlers.
    public static let tier3Crawlers: [AICrawler] = [
        AICrawler(
            name: "CCBot",
            userAgent: "CCBot",
            owner: "Common Crawl",
            purpose: "Open dataset for AI training",
            tier: .tier3,
            recommendation: .contextDependent
        ),
        AICrawler(
            name: "anthropic-ai",
            userAgent: "anthropic-ai",
            owner: "Anthropic",
            purpose: "Anthropic model training",
            tier: .tier3,
            recommendation: .contextDependent
        ),
        AICrawler(
            name: "Bytespider",
            userAgent: "Bytespider",
            owner: "ByteDance",
            purpose: "TikTok and ByteDance AI training",
            tier: .tier3,
            recommendation: .contextDependent
        ),
        AICrawler(
            name: "cohere-ai",
            userAgent: "cohere-ai",
            owner: "Cohere",
            purpose: "Cohere model training",
            tier: .tier3,
            recommendation: .contextDependent
        ),
    ]

    /// All 14 crawlers across all tiers.
    public static let allCrawlers: [AICrawler] =
        tier1Crawlers + tier2Crawlers + tier3Crawlers
}

// MARK: - Scoring Weights

/// Static scoring weight constants for all GEO composite formulas.
/// Each weight group sums to 1.0.
public enum GEOWeights {

    // MARK: Composite GEO Score Weights (sum = 1.0)

    /// Citability weight in composite score.
    public static let citability: Double = 0.25
    /// Brand authority weight in composite score.
    public static let brandAuthority: Double = 0.20
    /// E-E-A-T weight in composite score.
    public static let contentEEAT: Double = 0.20
    /// Technical SEO weight in composite score.
    public static let technical: Double = 0.15
    /// Schema completeness weight in composite score.
    public static let schema: Double = 0.10
    /// Platform presence weight in composite score.
    public static let platform: Double = 0.10

    // MARK: Citability Sub-Weights (sum = 1.0)

    /// Answer block quality sub-weight.
    public static let answerBlockQuality: Double = 0.30
    /// Self-containment sub-weight.
    public static let selfContainment: Double = 0.25
    /// Structural readability sub-weight.
    public static let structuralReadability: Double = 0.20
    /// Statistical density sub-weight.
    public static let statisticalDensity: Double = 0.15
    /// Uniqueness signals sub-weight.
    public static let uniquenessSignals: Double = 0.10

    // MARK: AI Visibility Sub-Weights (sum = 1.0)

    /// Tier 1 crawler access sub-weight.
    public static let tier1Access: Double = 0.50
    /// Tier 2 crawler access sub-weight.
    public static let tier2Access: Double = 0.25
    /// No blanket blocks sub-weight.
    public static let noBlanketBlocks: Double = 0.15
    /// AI-specific files (llms.txt, etc.) sub-weight.
    public static let aiFiles: Double = 0.10

    // MARK: Technical SEO Sub-Weights (sum = 1.0)

    /// Server-side rendering capability sub-weight.
    public static let ssrCapability: Double = 0.25
    /// Meta tags sub-weight.
    public static let metaTags: Double = 0.15
    /// Crawlability sub-weight.
    public static let crawlability: Double = 0.15
    /// Security headers sub-weight.
    public static let securityHeaders: Double = 0.10
    /// Core Web Vitals sub-weight.
    public static let coreWebVitals: Double = 0.10
    /// Mobile optimization sub-weight.
    public static let mobileOptimization: Double = 0.10
    /// URL structure sub-weight.
    public static let urlStructure: Double = 0.05
    /// Server response sub-weight.
    public static let serverResponse: Double = 0.05
    /// Additional technical factors sub-weight.
    public static let additionalTechnical: Double = 0.05

    // MARK: Brand Authority Sub-Weights (sum = 1.0)

    /// YouTube platform weight.
    public static let youtube: Double = 0.25
    /// Reddit platform weight.
    public static let reddit: Double = 0.25
    /// Wikipedia platform weight.
    public static let wikipedia: Double = 0.20
    /// LinkedIn platform weight.
    public static let linkedin: Double = 0.15
    /// Other platforms weight.
    public static let otherPlatforms: Double = 0.15
}

// MARK: - AI Platforms

/// Major AI search platforms that GEO optimizes for.
public enum AIPlatform: String, CaseIterable, Sendable {
    case googleAIO = "google_aio" // LIVE: enumerated by MCP clients via CaseIterable
    case chatGPT = "chatgpt" // LIVE: enumerated by MCP clients via CaseIterable
    case perplexity = "perplexity" // LIVE: enumerated by MCP clients via CaseIterable
    case gemini = "gemini" // LIVE: enumerated by MCP clients via CaseIterable
    case bingCopilot = "bing_copilot" // LIVE: enumerated by MCP clients via CaseIterable
}

// MARK: - Content Benchmarks

/// Page-type-specific word count and readability benchmarks.
public struct ContentBenchmark: Sendable {
    /// Page type identifier.
    public let pageType: String
    /// Minimum word count threshold.
    public let minimumWords: Int
    /// Lower bound of ideal word count range.
    public let idealRangeMin: Int
    /// Upper bound of ideal word count range.
    public let idealRangeMax: Int
    /// Minimum target Flesch reading ease score.
    public let targetFleschMin: Double
    /// Maximum target Flesch reading ease score.
    public let targetFleschMax: Double
}

/// Benchmarks for different page types, keyed by type name.
public enum ContentBenchmarks {
    /// All page-type benchmarks keyed by type name.
    public static let all: [String: ContentBenchmark] = [
        "homepage": ContentBenchmark(
            pageType: "homepage",
            minimumWords: 300,
            idealRangeMin: 500,
            idealRangeMax: 1000,
            targetFleschMin: 50.0,
            targetFleschMax: 70.0
        ),
        "blog": ContentBenchmark(
            pageType: "blog",
            minimumWords: 800,
            idealRangeMin: 1500,
            idealRangeMax: 2500,
            targetFleschMin: 45.0,
            targetFleschMax: 65.0
        ),
        "pillar": ContentBenchmark(
            pageType: "pillar",
            minimumWords: 2000,
            idealRangeMin: 3000,
            idealRangeMax: 5000,
            targetFleschMin: 40.0,
            targetFleschMax: 60.0
        ),
        "product": ContentBenchmark(
            pageType: "product",
            minimumWords: 300,
            idealRangeMin: 500,
            idealRangeMax: 1000,
            targetFleschMin: 50.0,
            targetFleschMax: 70.0
        ),
        "service": ContentBenchmark(
            pageType: "service",
            minimumWords: 500,
            idealRangeMin: 800,
            idealRangeMax: 1500,
            targetFleschMin: 45.0,
            targetFleschMax: 65.0
        ),
        "about": ContentBenchmark(
            pageType: "about",
            minimumWords: 300,
            idealRangeMin: 500,
            idealRangeMax: 1000,
            targetFleschMin: 50.0,
            targetFleschMax: 70.0
        ),
        "faq": ContentBenchmark(
            pageType: "faq",
            minimumWords: 500,
            idealRangeMin: 800,
            idealRangeMax: 2000,
            targetFleschMin: 55.0,
            targetFleschMax: 75.0
        ),
    ]
}

// MARK: - sameAs Platforms

/// A platform for JSON-LD sameAs auditing, with priority and point value.
public struct SameAsPlatform: Sendable {
    /// Crawler display name.
    public let name: String
    /// Substring to match in sameAs URLs.
    public let urlPattern: String
    /// Priority (1 = highest).
    public let priority: Int
    /// Maximum points awarded for this item.
    public let maxPoints: Double
}

/// Priority-ordered platforms for sameAs schema auditing. Total max points = 15.
public enum SameAsPlatforms {
    /// All priority-ordered sameAs platforms.
    public static let all: [SameAsPlatform] = [
        SameAsPlatform(name: "Wikipedia", urlPattern: "wikipedia.org", priority: 1, maxPoints: 3.0),
        SameAsPlatform(name: "Wikidata", urlPattern: "wikidata.org", priority: 2, maxPoints: 3.0),
        SameAsPlatform(name: "LinkedIn", urlPattern: "linkedin.com", priority: 3, maxPoints: 2.0),
        SameAsPlatform(name: "YouTube", urlPattern: "youtube.com", priority: 4, maxPoints: 2.0),
        SameAsPlatform(name: "Twitter", urlPattern: "twitter.com", priority: 5, maxPoints: 2.0),
        SameAsPlatform(name: "Facebook", urlPattern: "facebook.com", priority: 6, maxPoints: 1.0),
        SameAsPlatform(name: "GitHub", urlPattern: "github.com", priority: 7, maxPoints: 1.0),
        SameAsPlatform(name: "Crunchbase", urlPattern: "crunchbase.com", priority: 8, maxPoints: 1.0),
    ]
}

// MARK: - Security Headers

/// A security header specification with its name, HTTP key, and max score points.
public struct SecurityHeaderSpec: Sendable {
    /// Header display name.
    public let name: String
    /// HTTP header key to check.
    public let headerKey: String
    /// Maximum points awarded for this header.
    public let maxPoints: Double
}

/// The 6 security headers evaluated in technical SEO scoring. Total = 100 points.
public enum SecurityHeaders {
    /// All security headers evaluated in scoring.
    public static let all: [SecurityHeaderSpec] = [
        SecurityHeaderSpec(name: "HSTS", headerKey: "strict-transport-security", maxPoints: 20.0),
        SecurityHeaderSpec(name: "CSP", headerKey: "content-security-policy", maxPoints: 20.0),
        SecurityHeaderSpec(name: "X-Frame-Options", headerKey: "x-frame-options", maxPoints: 15.0),
        SecurityHeaderSpec(name: "X-Content-Type-Options", headerKey: "x-content-type-options", maxPoints: 15.0),
        SecurityHeaderSpec(name: "Referrer-Policy", headerKey: "referrer-policy", maxPoints: 15.0),
        SecurityHeaderSpec(name: "Permissions-Policy", headerKey: "permissions-policy", maxPoints: 15.0),
    ]
}

// MARK: - Citability Constants

/// Scoring thresholds and optimal ranges for citability analysis.
public enum CitabilityConstants {
    /// Minimum word count for optimal AI-citable passage (Princeton research).
    public static let optimalWordCountMin: Int = 134
    /// Maximum word count for optimal AI-citable passage (Princeton research).
    public static let optimalWordCountMax: Int = 167
    /// Grade A threshold.
    public static let gradeA: Double = 80.0
    /// Grade B threshold.
    public static let gradeB: Double = 65.0
    /// Grade C threshold.
    public static let gradeC: Double = 50.0
    /// Grade D threshold.
    public static let gradeD: Double = 35.0
}
