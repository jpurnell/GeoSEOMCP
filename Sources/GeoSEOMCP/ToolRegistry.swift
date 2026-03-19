import Foundation
import SwiftMCPServer

/// Returns all registered GeoSEO MCP tool handlers.
public func allToolHandlers() -> [any MCPToolHandler] {
    var handlers: [any MCPToolHandler] = []
    handlers += getUtilityTools()
    handlers += getCitabilityTools()
    return handlers
}
