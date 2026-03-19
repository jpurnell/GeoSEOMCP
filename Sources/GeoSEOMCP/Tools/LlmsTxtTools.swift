import Foundation
import SwiftMCPServer

/// Returns all llms.txt tools.
public func getLlmsTxtTools() -> [any MCPToolHandler] {
    return [
        ValidateLlmsTxtTool(),
        CategorizeUrlsForLlmsTxtTool(),
    ]
}

// MARK: - llms.txt Validation

/// Result of validating llms.txt content.
public struct LlmsTxtValidationResult: Sendable {
    public let isValid: Bool
    public let hasTitle: Bool
    public let hasDescription: Bool
    public let hasSections: Bool
    public let sectionCount: Int
    public let linkCount: Int
    public let issues: [String]
}

/// Validate llms.txt content against the specification.
/// Expected format: H1 title, blockquote description, H2 sections with markdown links.
public func validateLlmsTxt(_ content: String) -> LlmsTxtValidationResult {
    guard !content.isEmpty else {
        return LlmsTxtValidationResult(
            isValid: false, hasTitle: false, hasDescription: false,
            hasSections: false, sectionCount: 0, linkCount: 0,
            issues: ["Content is empty"]
        )
    }

    var issues: [String] = []

    // Check for H1 title
    let hasTitle = content.range(of: #"(?m)^# .+"#, options: .regularExpression) != nil
    if !hasTitle {
        issues.append("Missing H1 title (# Title)")
    }

    // Check for blockquote description
    let hasDescription = content.range(of: #"(?m)^> .+"#, options: .regularExpression) != nil
    if !hasDescription {
        issues.append("Missing blockquote description (> Description)")
    }

    // Count H2 sections
    let sectionPattern = #"(?m)^## .+"#
    let sectionCount: Int
    if let regex = try? NSRegularExpression(pattern: sectionPattern) {
        let range = NSRange(content.startIndex..., in: content)
        sectionCount = regex.numberOfMatches(in: content, range: range)
    } else {
        sectionCount = 0
    }
    let hasSections = sectionCount > 0
    if !hasSections {
        issues.append("No H2 sections found (## Section Name)")
    }

    // Count markdown links [text](url)
    let linkPattern = #"\[([^\]]+)\]\(([^)]+)\)"#
    let linkCount: Int
    if let regex = try? NSRegularExpression(pattern: linkPattern) {
        let range = NSRange(content.startIndex..., in: content)
        linkCount = regex.numberOfMatches(in: content, range: range)
    } else {
        linkCount = 0
    }
    if linkCount == 0 {
        issues.append("No markdown links found - [Text](URL)")
    }

    let isValid = hasTitle && hasSections && linkCount > 0

    return LlmsTxtValidationResult(
        isValid: isValid, hasTitle: hasTitle, hasDescription: hasDescription,
        hasSections: hasSections, sectionCount: sectionCount, linkCount: linkCount,
        issues: issues
    )
}

// MARK: - URL Categorization

/// URL category for llms.txt organization.
public struct URLCategory: Sendable {
    public let url: String
    public let category: String
    public let suggestedSection: String
}

/// Categorize URLs into llms.txt sections based on path patterns.
public func categorizeUrlsForLlmsTxt(_ urls: [String]) -> [String: URLCategory] {
    var result: [String: URLCategory] = [:]

    let patterns: [(pattern: String, category: String, section: String)] = [
        ("/pricing", "Products", "Products & Pricing"),
        ("/product", "Products", "Products & Pricing"),
        ("/features", "Products", "Products & Pricing"),
        ("/plans", "Products", "Products & Pricing"),
        ("/blog", "Resources", "Resources & Blog"),
        ("/docs", "Resources", "Documentation"),
        ("/documentation", "Resources", "Documentation"),
        ("/guide", "Resources", "Documentation"),
        ("/help", "Resources", "Documentation"),
        ("/api", "Resources", "API Reference"),
        ("/about", "Company", "Company Info"),
        ("/team", "Company", "Company Info"),
        ("/careers", "Company", "Company Info"),
        ("/contact", "Company", "Company Info"),
        ("/case-stud", "Resources", "Case Studies"),
        ("/testimonial", "Resources", "Case Studies"),
        ("/faq", "Resources", "FAQ"),
        ("/support", "Resources", "Support"),
        ("/service", "Products", "Services"),
    ]

    for url in urls {
        let lower = url.lowercased()
        var matched = false

        for (pattern, category, section) in patterns {
            if lower.contains(pattern) {
                result[url] = URLCategory(url: url, category: category, suggestedSection: section)
                matched = true
                break
            }
        }

        if !matched {
            result[url] = URLCategory(url: url, category: "Other", suggestedSection: "Optional")
        }
    }

    return result
}

// MARK: - validate_llmstxt Tool

/// Validate llms.txt content against the specification.
public struct ValidateLlmsTxtTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "validate_llmstxt",
        description: """
        Validate llms.txt file content against the specification.

        Checks for required elements:
        - H1 title (# Company Name)
        - Blockquote description (> Company description)
        - H2 sections (## Section Name)
        - Markdown links [Text](URL) with descriptions

        Returns validation status, issues found, and section/link counts.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "content": MCPSchemaProperty(
                    type: "string",
                    description: "The raw llms.txt file content to validate"
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
        let result = validateLlmsTxt(content)

        var output = """
        llms.txt Validation Report

        Status: \(result.isValid ? "VALID" : "INVALID")

        Checklist:
          Title (H1): \(result.hasTitle ? "✓" : "✗")
          Description (blockquote): \(result.hasDescription ? "✓" : "✗")
          Sections (H2): \(result.hasSections ? "✓ (\(result.sectionCount) found)" : "✗")
          Links: \(result.linkCount > 0 ? "✓ (\(result.linkCount) found)" : "✗")
        """

        if !result.issues.isEmpty {
            output += "\n\nIssues:"
            for issue in result.issues {
                output += "\n  • \(issue)"
            }
        }

        return .success(text: output)
    }
}

// MARK: - categorize_urls_for_llmstxt Tool

/// Categorize URLs into suggested llms.txt sections.
public struct CategorizeUrlsForLlmsTxtTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "categorize_urls_for_llmstxt",
        description: """
        Categorize a list of URLs into suggested llms.txt sections.

        Analyzes URL paths to suggest appropriate section groupings:
        - Products & Pricing (/pricing, /products, /features)
        - Resources & Blog (/blog, /resources)
        - Documentation (/docs, /guide, /api)
        - Company Info (/about, /team, /contact)
        - Case Studies (/case-studies, /testimonials)

        Helps structure an llms.txt file from a site's existing pages.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "urls": MCPSchemaProperty(
                    type: "array",
                    description: "List of URL paths to categorize",
                    items: MCPSchemaItems(type: "string")
                ),
            ],
            required: ["urls"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("urls")
        }

        let urls = try args.getStringArray("urls")
        let categories = categorizeUrlsForLlmsTxt(urls)

        if categories.isEmpty {
            return .success(text: "URL Categorization\n\nNo URLs provided.")
        }

        // Group by suggested section
        var sections: [String: [URLCategory]] = [:]
        for (_, cat) in categories {
            sections[cat.suggestedSection, default: []].append(cat)
        }

        var output = "URL Categorization for llms.txt\n\nURLs analyzed: \(urls.count)\n"

        for (section, items) in sections.sorted(by: { $0.key < $1.key }) {
            output += "\n## \(section)"
            for item in items {
                output += "\n  \(item.url) → \(item.category)"
            }
        }

        return .success(text: output)
    }
}
