// swift-tools-version: 6.2
// legibility:description: A Model Context Protocol (MCP) server providing 29 tools for Generative Engine Optimization (GEO) analysis.
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
        .package(url: "https://github.com/jpurnell/SwiftMCPServer.git", from: "1.1.0"),
        .package(url: "https://github.com/jpurnell/swift-sdk.git", exact: "0.10.3"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "GeoSEOMCP",
            dependencies: [
                .product(name: "SwiftMCPServer", package: "SwiftMCPServer"),
                .product(name: "MCP", package: "swift-sdk"),
            ],
            // SwiftPM does not auto-handle .docc catalogues here, so declare it
            // explicitly. `exclude` would also silence the warning, but it drops
            // the catalogue from the DocC build entirely.
            resources: [.copy("GeoSEOMCP.docc")]
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
