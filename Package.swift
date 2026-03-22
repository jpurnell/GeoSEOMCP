// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-geo-seo-mcp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "GeoSEOMCP", targets: ["GeoSEOMCP"]),
        .executable(name: "geoseo-mcp-server", targets: ["GeoSEOMCPServer"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpurnell/SwiftMCPServer.git", branch: "main"),
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", exact: "0.10.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "GeoSEOMCP",
            dependencies: [
                .product(name: "SwiftMCPServer", package: "SwiftMCPServer"),
                .product(name: "MCP", package: "swift-sdk"),
            ]
        ),
        .executableTarget(
            name: "GeoSEOMCPServer",
            dependencies: [
                "GeoSEOMCP",
                .product(name: "SwiftMCPServer", package: "SwiftMCPServer"),
            ]
        ),
        .testTarget(
            name: "GeoSEOMCPTests",
            dependencies: [
                "GeoSEOMCP",
                .product(name: "SwiftMCPServer", package: "SwiftMCPServer"),
            ]
        )
    ]
)
