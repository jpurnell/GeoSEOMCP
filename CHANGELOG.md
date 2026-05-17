# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed
- Bumped swift-tools-version to 6.2
- Switched to jpurnell/swift-sdk fork (0.10.3) for Swift 6.3 concurrency fix
- Replaced String(format:) with .formatted() API throughout
- Added 100% public API documentation coverage

### Fixed
- SendingRisksDataRace diagnostics under Swift 6.3 strict concurrency
- Floating-point division zero guards in citability scoring
- Weak test assertions replaced with precise value checks

## [0.1.0] - 2025-05-10

### Added
- 29 MCP tools across 9 categories (citability, content, crawler, schema, technical, brand, llms.txt, composite, utility)
- Structured JSON output for all tools via GeoSEOResult envelope
- 5 workflow prompt templates for GEO analysis
- 16 resource documents (guides, templates, examples)
- Linux compatibility with canImport(NaturalLanguage) guards
- 183 tests covering domain logic, tool registration, and schema contracts
