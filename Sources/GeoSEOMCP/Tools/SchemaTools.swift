import Foundation
import SwiftMCPServer

/// Returns all schema validation tools.
public func getSchemaTools() -> [any MCPToolHandler] {
    return [
        ValidateJsonLdTool(),
        AuditSameAsCoverageTool(),
        ScoreSchemaCompletenessTool(),
        GenerateSchemaTemplateTool(),
    ]
}

// MARK: - validate_json_ld Tool

/// Validate JSON-LD structured data.
public struct ValidateJsonLdTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "validate_json_ld",
        description: """
        Validate JSON-LD structured data for schema.org compliance.

        Checks for:
        - Valid JSON syntax
        - Required @context (schema.org)
        - Required @type
        - Common properties for the detected type
        - sameAs array presence for Organization types
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "json_ld": MCPSchemaProperty(
                    type: "string",
                    description: "JSON-LD content as a JSON string"
                ),
            ],
            required: ["json_ld"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("json_ld")
        }

        let jsonString = try args.getString("json_ld")

        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return .success(text: """
            JSON-LD Validation

            Status: INVALID
            Error: Invalid JSON syntax — could not parse the provided content.
            """)
        }

        var issues: [String] = []
        var findings: [String] = []

        // Check @context
        if let context = json["@context"] as? String {
            if context.contains("schema.org") {
                findings.append("@context: ✓ schema.org")
            } else {
                issues.append("@context does not reference schema.org")
            }
        } else {
            issues.append("Missing @context — should be \"https://schema.org\"")
        }

        // Check @type
        let schemaType: String
        if let type = json["@type"] as? String {
            schemaType = type
            findings.append("@type: ✓ \(type)")
        } else {
            schemaType = "Unknown"
            issues.append("Missing @type — required for schema.org validation")
        }

        // Check common properties based on type
        let expectedProps: [String]
        switch schemaType {
        case "Organization":
            expectedProps = ["name", "url", "logo", "sameAs", "description"]
        case "WebSite":
            expectedProps = ["name", "url", "potentialAction"]
        case "Article", "BlogPosting", "NewsArticle":
            expectedProps = ["headline", "author", "datePublished", "image"]
        case "Product":
            expectedProps = ["name", "description", "offers", "image"]
        case "LocalBusiness":
            expectedProps = ["name", "address", "telephone", "openingHours"]
        case "FAQPage":
            expectedProps = ["mainEntity"]
        default:
            expectedProps = ["name"]
        }

        for prop in expectedProps {
            if json[prop] != nil {
                findings.append("\(prop): ✓ present")
            } else {
                issues.append("Missing recommended property: \(prop)")
            }
        }

        let status = issues.isEmpty ? "VALID" : "HAS ISSUES"
        let propertyCount = json.keys.filter { !$0.hasPrefix("@") }.count

        var output = """
        JSON-LD Validation

        Status: \(status)
        Type: \(schemaType)
        Properties: \(propertyCount)

        Findings:
        """
        for finding in findings { output += "\n  \(finding)" }

        if !issues.isEmpty {
            output += "\n\nIssues:"
            for issue in issues { output += "\n  ✗ \(issue)" }
        }

        return .success(text: output)
    }
}

// MARK: - audit_sameas_coverage Tool

/// Audit sameAs coverage against priority platforms.
public struct AuditSameAsCoverageTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "audit_sameas_coverage",
        description: """
        Audit sameAs URL coverage against priority platforms.

        Checks provided sameAs URLs against 8 priority platforms:
        Wikipedia (3pts), Wikidata (3pts), LinkedIn (2pts), YouTube (2pts),
        Twitter (2pts), Facebook (1pt), GitHub (1pt), Crunchbase (1pt).

        Maximum score: 15 points. Reports which platforms are covered \
        and which are missing.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "sameas_urls": MCPSchemaProperty(
                    type: "array",
                    description: "List of sameAs URLs from the Organization schema",
                    items: MCPSchemaItems(type: "string")
                ),
            ],
            required: ["sameas_urls"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("sameas_urls")
        }

        let urls = try args.getStringArray("sameas_urls")

        var totalPoints = 0.0
        var covered: [(String, Double)] = []
        var missing: [(String, Double)] = []

        for platform in SameAsPlatforms.all {
            let found = urls.contains { $0.lowercased().contains(platform.urlPattern) }
            if found {
                totalPoints += platform.maxPoints
                covered.append((platform.name, platform.maxPoints))
            } else {
                missing.append((platform.name, platform.maxPoints))
            }
        }

        let percentage = (totalPoints / 15.0) * 100.0

        var output = """
        sameAs Coverage Audit

        Score: \(String(format: "%.0f", totalPoints)) / 15 points (\(String(format: "%.0f", percentage))%)
        Platforms Covered: \(covered.count) / \(SameAsPlatforms.all.count)
        """

        if !covered.isEmpty {
            output += "\n\nCovered:"
            for (name, points) in covered {
                output += "\n  ✓ \(name) (+\(String(format: "%.0f", points)) pts)"
            }
        }

        if !missing.isEmpty {
            output += "\n\nMissing:"
            for (name, points) in missing {
                output += "\n  ✗ \(name) (\(String(format: "%.0f", points)) pts available)"
            }
        }

        return .success(text: output)
    }
}

// MARK: - score_schema_completeness Tool

/// Score schema.org implementation completeness.
public struct ScoreSchemaCompletenessTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "score_schema_completeness",
        description: """
        Score the completeness of a site's schema.org implementation.

        Evaluates which schema types are present and scores based on:
        - Organization (essential): 25 points
        - WebSite with SearchAction: 20 points
        - Article/BlogPosting: 15 points
        - BreadcrumbList: 15 points
        - FAQPage: 10 points
        - Product/LocalBusiness: 10 points
        - Other types: 5 points each (up to 5 additional)

        Maximum score: 100 points.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "schema_types": MCPSchemaProperty(
                    type: "array",
                    description: "List of schema.org @type values found on the site",
                    items: MCPSchemaItems(type: "string")
                ),
            ],
            required: ["schema_types"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("schema_types")
        }

        let types = try args.getStringArray("schema_types")
        let typeSet = Set(types.map { $0.lowercased() })

        var score = 0.0
        var found: [(String, Double)] = []
        var missing: [(String, Double)] = []

        let scoredTypes: [(String, [String], Double)] = [
            ("Organization", ["organization"], 25),
            ("WebSite", ["website"], 20),
            ("Article/BlogPosting", ["article", "blogposting", "newsarticle"], 15),
            ("BreadcrumbList", ["breadcrumblist"], 15),
            ("FAQPage", ["faqpage"], 10),
            ("Product/LocalBusiness", ["product", "localbusiness"], 10),
        ]

        for (name, matchTypes, points) in scoredTypes {
            if matchTypes.contains(where: { typeSet.contains($0) }) {
                score += points
                found.append((name, points))
            } else {
                missing.append((name, points))
            }
        }

        // Bonus for additional types (5 pts each, max 5 additional)
        let knownTypes = Set(scoredTypes.flatMap { $0.1 })
        let additionalTypes = typeSet.filter { !knownTypes.contains($0) }
        let additionalBonus = min(Double(additionalTypes.count) * 5.0, 5.0)
        score += additionalBonus

        score = min(score, 100)

        var output = """
        Schema Completeness Score

        Score: \(String(format: "%.0f", score)) / 100
        Types Found: \(types.count)
        """

        if !found.isEmpty {
            output += "\n\nImplemented:"
            for (name, points) in found {
                output += "\n  ✓ \(name) (+\(String(format: "%.0f", points)) pts)"
            }
        }

        if additionalBonus > 0 {
            output += "\n  + Additional types bonus: +\(String(format: "%.0f", additionalBonus)) pts"
        }

        if !missing.isEmpty {
            output += "\n\nMissing (recommended):"
            for (name, points) in missing {
                output += "\n  ✗ \(name) (\(String(format: "%.0f", points)) pts)"
            }
        }

        return .success(text: output)
    }
}

// MARK: - generate_schema_template Tool

/// Generate JSON-LD schema templates for different business types.
public struct GenerateSchemaTemplateTool: MCPToolHandler, Sendable {
    public let tool = MCPTool(
        name: "generate_schema_template",
        description: """
        Generate a JSON-LD schema.org template for a business type.

        Available templates:
        - organization: Standard Organization schema
        - local-business: LocalBusiness with address and hours
        - article: Article/BlogPosting with author
        - product: Product with offers
        - software: SoftwareApplication for SaaS
        - website: WebSite with SearchAction

        Returns ready-to-use JSON-LD with placeholder values.
        """,
        inputSchema: MCPToolInputSchema(
            properties: [
                "business_type": MCPSchemaProperty(
                    type: "string",
                    description: "Template type: organization, local-business, article, product, software, website"
                ),
            ],
            required: ["business_type"]
        )
    )

    public init() {}

    public func execute(arguments: [String: AnyCodable]?) async throws -> MCPToolCallResult {
        guard let args = arguments else {
            throw ToolError.missingRequiredArgument("business_type")
        }

        let businessType = try args.getString("business_type")

        let template: String
        switch businessType.lowercased() {
        case "organization":
            template = """
            {
              "@context": "https://schema.org",
              "@type": "Organization",
              "name": "[Company Name]",
              "url": "[https://example.com]",
              "logo": "[https://example.com/logo.png]",
              "description": "[Company description]",
              "sameAs": [
                "[https://en.wikipedia.org/wiki/Company]",
                "[https://www.linkedin.com/company/name]",
                "[https://twitter.com/handle]",
                "[https://www.youtube.com/@channel]"
              ],
              "contactPoint": {
                "@type": "ContactPoint",
                "contactType": "customer service",
                "email": "[contact@example.com]"
              }
            }
            """
        case "local-business":
            template = """
            {
              "@context": "https://schema.org",
              "@type": "LocalBusiness",
              "name": "[Business Name]",
              "url": "[https://example.com]",
              "telephone": "[+1-555-555-5555]",
              "address": {
                "@type": "PostalAddress",
                "streetAddress": "[123 Main St]",
                "addressLocality": "[City]",
                "addressRegion": "[State]",
                "postalCode": "[12345]",
                "addressCountry": "US"
              },
              "openingHours": "Mo-Fr 09:00-17:00",
              "geo": {
                "@type": "GeoCoordinates",
                "latitude": "[0.0]",
                "longitude": "[0.0]"
              }
            }
            """
        case "article":
            template = """
            {
              "@context": "https://schema.org",
              "@type": "Article",
              "headline": "[Article Title]",
              "author": {
                "@type": "Person",
                "name": "[Author Name]"
              },
              "datePublished": "[2024-01-01]",
              "dateModified": "[2024-01-15]",
              "image": "[https://example.com/image.jpg]",
              "publisher": {
                "@type": "Organization",
                "name": "[Publisher Name]",
                "logo": {
                  "@type": "ImageObject",
                  "url": "[https://example.com/logo.png]"
                }
              }
            }
            """
        case "product":
            template = """
            {
              "@context": "https://schema.org",
              "@type": "Product",
              "name": "[Product Name]",
              "description": "[Product description]",
              "image": "[https://example.com/product.jpg]",
              "brand": {
                "@type": "Brand",
                "name": "[Brand Name]"
              },
              "offers": {
                "@type": "Offer",
                "price": "[99.99]",
                "priceCurrency": "USD",
                "availability": "https://schema.org/InStock"
              }
            }
            """
        case "software":
            template = """
            {
              "@context": "https://schema.org",
              "@type": "SoftwareApplication",
              "name": "[App Name]",
              "applicationCategory": "[BusinessApplication]",
              "operatingSystem": "Web",
              "offers": {
                "@type": "Offer",
                "price": "[0]",
                "priceCurrency": "USD"
              },
              "aggregateRating": {
                "@type": "AggregateRating",
                "ratingValue": "[4.5]",
                "ratingCount": "[100]"
              }
            }
            """
        case "website":
            template = """
            {
              "@context": "https://schema.org",
              "@type": "WebSite",
              "name": "[Site Name]",
              "url": "[https://example.com]",
              "potentialAction": {
                "@type": "SearchAction",
                "target": "[https://example.com/search?q={search_term_string}]",
                "query-input": "required name=search_term_string"
              }
            }
            """
        default:
            let validTypes = "organization, local-business, article, product, software, website"
            return .success(text: """
            Schema Template Generator

            Unknown business type: \(businessType)
            Available types: \(validTypes)
            """)
        }

        return .success(text: """
        Schema Template: \(businessType)

        ```json
        \(template)
        ```

        Replace all [placeholder] values with your actual data.
        """)
    }
}
