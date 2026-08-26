# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- DocC documentation catalogue at `Sources/GeoSEOMCP/GeoSEOMCP.docc`, curating all 84
  public symbols into 12 topic sections with an overview of the nine analysis dimensions

### Changed
- Bumped swift-tools-version to 6.2
- Switched to jpurnell/swift-sdk fork (0.10.3) for Swift 6.3 concurrency fix
- Replaced String(format:) with .formatted() API throughout
- Added 100% public API documentation coverage
- Declared the DocC catalogue as an explicit target resource in `Package.swift`, because
  SwiftPM 6.4 does not auto-handle `.docc` directories and otherwise warns about them

### Fixed
- SendingRisksDataRace diagnostics under Swift 6.3 strict concurrency
- Floating-point division zero guards in citability scoring
- Weak test assertions replaced with precise value checks
- `parseRobotsTxt` split lines on `CharacterSet.newlines`, which counts a CRLF as two
  separators and yields an empty element between every pair of lines. Now splits on
  `\.isNewline`. No behaviour change in practice — the parser already skipped empty
  lines — but the hazard is gone and the split no longer allocates a String per line

## [0.1.0] - 2026-07-05

### Added
- 29 MCP tools across 9 categories (citability, content, crawler, schema, technical, brand, llms.txt, composite, utility)
- Structured JSON output for all tools via GeoSEOResult envelope
- 5 workflow prompt templates for GEO analysis
- 16 resource documents (guides, templates, examples)
- Linux compatibility with canImport(NaturalLanguage) guards
- 183 tests covering domain logic, tool registration, and schema contracts

[Unreleased]: https://github.com/jpurnell/GeoSEOMCP/compare/0.1.0...HEAD
[0.1.0]: https://github.com/jpurnell/GeoSEOMCP/releases/tag/0.1.0
