# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Security
- **SwiftMCPServer 5.0.0** (was 4.4.3). A security release of the package this server is
  built on, and a breaking one. What it changes here:
  - **The HTTP listener binds `127.0.0.1` unless asked for more.** Under 4.x the address
    was written into the package and every interface was listened on. A deployment that
    is reached from another machine — the public one on roseclub.org, port 8081 — must
    now be started with `--host 0.0.0.0`, or it will come up and be unreachable. The
    README's new "Running over HTTP" section shows both forms. **This repository holds no
    launch configuration** (no plist, no deploy script), so the live service's launchd
    arguments have to be changed where they live, at deploy time; nothing here does it.
  - **A failed `resources/read` keeps its message.** 5.0.0 returns an error's text only
    if its type conforms to `CallerVisibleError`, and otherwise answers with a generic
    sentence and a reference id. `ResourceError` now conforms — its one message,
    `Resource not found: <uri>`, repeats the caller's own URI and nothing about the
    server — so an unknown URI is still answered with that sentence.
  - **Tool errors lose a prefix.** Every tool here throws only `ToolError`, which the
    package itself conforms, so the text is unchanged except that the registry no longer
    prepends `Execution error: `. A client that matched on that prefix must stop.
  - Session ids are 64-character random tokens rather than UUIDs, request bodies over
    4 MiB are refused with `413` before authentication, and API keys are hashed with
    SHA-256 and compared in constant time. None needs a change in this package.

### Added
- `ResourceError: CallerVisibleError`, with four tests pinning the exact text an unknown
  URI is answered with, both on the type and through `MCPServer.readResource(from:uri:)`
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
- **`calculate_eeat_score` graded a rating that was not a number.** A NaN is false against
  every threshold in the grading chain, so it fell to the trailing `else` and came back
  as `Final Score: NaN / 110 — Very Poor`; an infinity clamped to a confident 0 or 110.
  The sum is now tested before it is graded, and a non-finite rating is refused as
  `Invalid arguments: <name> must be a finite number` (finite ratings that overflow as
  `Invalid arguments: the ratings are too large to add up`). JSON cannot carry these values, so
  no client over the wire could have sent one; a caller of the handler in-process could.
  Found by the gate's `fallback` checker (`fallback.classification-omits-nan`), which
  was reporting it as a warning on `main`
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
