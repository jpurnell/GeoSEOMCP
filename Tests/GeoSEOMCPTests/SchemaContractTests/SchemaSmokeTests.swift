import Testing
import Foundation
@testable import GeoSEOMCP
@testable import SwiftMCPServer

@Suite("Schema Smoke Tests")
struct SchemaSmokeTests {

    @Test("All tools have non-empty name and description")
    func testNamesAndDescriptions() {
        let schemas = allToolSchemas()
        for schema in schemas {
            #expect(!schema.name.isEmpty, "Tool has empty name")
            #expect(!schema.description.isEmpty, "Tool \(schema.name) has empty description")
        }
    }

    @Test("All required params have type and description")
    func testRequiredParamMetadata() {
        let schemas = allToolSchemas()
        for schema in schemas {
            for param in schema.requiredParams {
                #expect(schema.paramTypes[param] != nil,
                        "Tool \(schema.name): required param '\(param)' missing type")
                #expect(schema.paramDescriptions[param] != nil,
                        "Tool \(schema.name): required param '\(param)' missing description")
            }
        }
    }

    @Test("Minimal valid args do not crash any tool")
    func testMinimalArgsDontCrash() async throws {
        let handlers = allTestToolHandlers()
        for handler in handlers {
            let schema = extractSchema(handler)
            let args = generateMinimalValidArgs(schema)
            // Should not crash — may return error result, that's fine
            _ = try? await handler.execute(arguments: args)
        }
    }
}
