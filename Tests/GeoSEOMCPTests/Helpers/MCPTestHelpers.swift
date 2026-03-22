import Testing
import Foundation
import MCP
@testable import GeoSEOMCP
@testable import SwiftMCPServer

// MARK: - MCPToolCallResult Convenience

extension MCPToolCallResult {
    /// Whether this result represents an error
    var isError: Bool {
        return result.isError ?? false
    }

    /// Extract the rich text content from the result.
    ///
    /// For structured results (two content blocks), returns the second block (rich text).
    /// For legacy single-block results, returns the first block.
    var text: String {
        // Structured results: [json, richText] — return richText
        if result.content.count >= 2 {
            if case .text(let string) = result.content[1] {
                return string
            }
        }
        // Legacy or single-block: return first
        guard let firstContent = result.content.first else {
            return ""
        }
        switch firstContent {
        case .text(let string):
            return string
        case .image, .resource, .audio:
            return ""
        default:
            return ""
        }
    }

    /// Extract the structured JSON string from the first content block.
    var jsonText: String? {
        guard result.content.count >= 2,
              case .text(let string) = result.content.first else {
            return nil
        }
        return string
    }
}

// MARK: - Argument Construction Helpers

/// Build AnyCodable arguments from a JSON string, matching the MCP wire format path.
func decodeArguments(_ json: String) throws -> [String: AnyCodable] {
    guard let data = json.data(using: .utf8) else {
        throw MCPTestError.invalidJson
    }
    let mcpValue = try JSONDecoder().decode(MCP.Value.self, from: data)
    guard case .object(let dict) = mcpValue else {
        throw MCPTestError.decodingFailed("JSON must be an object")
    }
    return dict.mapValues { AnyCodable($0) }
}

/// Build AnyCodable arguments from a JSON string literal.
func argsFromJSON(_ json: String) -> [String: AnyCodable] {
    return (try? decodeArguments(json)) ?? [:]
}

// MARK: - Test Error Type

enum MCPTestError: Error, LocalizedError {
    case invalidJson
    case decodingFailed(String)
    case unexpectedResult(String)

    var errorDescription: String? {
        switch self {
        case .invalidJson:
            return "Invalid JSON in test"
        case .decodingFailed(let msg):
            return "Decoding failed: \(msg)"
        case .unexpectedResult(let msg):
            return "Unexpected result: \(msg)"
        }
    }
}

// MARK: - Tool Collection

/// Collect ALL registered tool handlers from all registration functions.
func allTestToolHandlers() -> [any MCPToolHandler] {
    return allToolHandlers()
}

/// Map of tool name -> tool handler for direct lookup
func toolHandlersByName() -> [String: any MCPToolHandler] {
    var map: [String: any MCPToolHandler] = [:]
    for handler in allTestToolHandlers() {
        map[handler.tool.name] = handler
    }
    return map
}
