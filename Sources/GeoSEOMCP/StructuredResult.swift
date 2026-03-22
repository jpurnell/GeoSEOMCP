import Foundation
import MCP
import SwiftMCPServer

// MARK: - Structured Result Types

/// Envelope for structured JSON output from GeoSEO MCP tools.
///
/// Every tool returns this as the first content block (JSON), with the
/// existing rich text as the second content block. Consumers can detect
/// structured output by checking for `_schema == "geoseo/v1"`.
public struct GeoSEOResult: Codable, Sendable {
    /// Schema version discriminator. Always `"geoseo/v1"`.
    public let _schema: String

    /// The tool name (e.g., `"score_technical_seo"`).
    public let tool: String

    /// Whether this tool produces a score or is analysis-only.
    public let resultType: ResultType

    /// The primary score, if this is a scored tool.
    public let score: ScorePayload?

    /// Tool-specific structured data.
    public let data: [String: JSONValue]

    public init(
        tool: String,
        resultType: ResultType,
        score: ScorePayload? = nil,
        data: [String: JSONValue] = [:]
    ) {
        self._schema = "geoseo/v1"
        self.tool = tool
        self.resultType = resultType
        self.score = score
        self.data = data
    }
}

/// Whether a tool result includes a score or is purely analytical.
public enum ResultType: String, Codable, Sendable {
    case scored
    case analysis
}

/// A numeric score with its scale and optional letter grade.
public struct ScorePayload: Codable, Sendable {
    /// The primary score value.
    public let value: Double

    /// The maximum possible score (e.g., 100 or 110 for E-E-A-T).
    public let maximum: Double

    /// Optional letter grade (A-F, or descriptive like "Excellent").
    public let grade: String?

    public init(value: Double, maximum: Double, grade: String? = nil) {
        self.value = value
        self.maximum = maximum
        self.grade = grade
    }
}

// MARK: - JSON Value Type

/// A type-safe JSON value for structured data fields.
///
/// Using a custom enum instead of `Any` to keep everything `Codable` and `Sendable`.
public enum JSONValue: Codable, Sendable, Equatable {
    case string(String)
    case number(Double)
    case integer(Int)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Int.self) {
            self = .integer(v)
        } else if let v = try? container.decode(Double.self) {
            self = .number(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode([JSONValue].self) {
            self = .array(v)
        } else if let v = try? container.decode([String: JSONValue].self) {
            self = .object(v)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .number(let v): try container.encode(v)
        case .integer(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .null: try container.encodeNil()
        case .array(let v): try container.encode(v)
        case .object(let v): try container.encode(v)
        }
    }
}

// MARK: - MCPToolCallResult Extension

extension MCPToolCallResult {
    /// Create a result with both structured JSON (block 0) and rich text (block 1).
    ///
    /// Consumers detect structured output via `_schema: "geoseo/v1"` in block 0.
    /// The rich text in block 1 is preserved for human-readable display and PDF reports.
    public static func structured(json: GeoSEOResult, text: String) -> MCPToolCallResult {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let jsonString: String
        if let data = try? encoder.encode(json),
           let str = String(data: data, encoding: .utf8) {
            jsonString = str
        } else {
            // Fallback: return text-only if JSON encoding fails
            return .success(text: text)
        }

        return MCPToolCallResult(
            CallTool.Result(content: [.text(jsonString), .text(text)], isError: false)
        )
    }
}
