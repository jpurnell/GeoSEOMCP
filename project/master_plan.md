# GeoSEOMCP Master Plan

**Purpose:** Source of truth for project vision, architecture, and goals.

> **Provenance:** Written 2026-08-05 from README, `Package.swift`, and the source tree.

---

## Project Overview

### Mission

An MCP server providing 29 tools for **Generative Engine Optimization** — analysing how
well a page is understood, cited, and retrieved by AI systems rather than ranked by search
engines.

### Target Users
- Anyone whose content should be found and cited by AI assistants
- Agents auditing a site's machine-readability
- Authors deciding whether a page is citable in the form an LLM actually consumes

### Key Differentiators
- **Optimises for citation, not ranking.** Classic SEO targets a results page; this targets
  being quoted correctly by a model that read the page once
- **Knows the AI crawlers specifically** — `AICrawlerRegistry`, `AICrawler`, `AIPlatform`,
  and access analysis, because a `robots.txt` that admits Googlebot and excludes GPTBot is
  a decision most tooling will not surface
- **Passage-level citability**, not page-level scores — the unit a model quotes is a passage

---

## Architecture

- **Language:** Swift 6 · **Build:** SwiftPM · **Testing:** Swift Testing
- **Dependencies:** `SwiftMCPServer`, `swift-sdk`
- **Products:** `GeoSEOMCP` (library), `geoseo-mcp-server` (executable)

Transport, framing, and authentication come from
[`SwiftMCPServer`](../../SwiftMCPServer/project/master_plan.md); this package supplies
domain tools only.

16 source files, 14 test files — near parity, appropriate for a package that is mostly
analysis logic.

---

## Current Status

- [x] 29 tools across crawler access, content statistics, heading structure, citability,
      schema validation, and platform readiness

### Priorities
**[NEEDS INPUT]**

### A connection worth noting

The `Ignite` fork's structured-data work and this server's schema analysis are two halves of
one pipeline: generate pages carrying machine-readable schema, then audit whether AI systems
can actually use it. Neither plan currently states that as a goal. **[NEEDS INPUT]** —
whether it is one.

## Quality Standards

`coding_rules.md`, Swift 6 strict concurrency, zero warnings, DocC on public types.
**Analysis runs against fixed HTML fixtures, never live sites** — a test that fetches a real
page fails when that page changes, and reports someone else's edit as your regression.

## Roadmap

**[NEEDS INPUT]** — the crawler registry is the part most exposed to the outside world;
new platforms appear and user-agent strings change, so it needs a maintenance story.

---

**Last Updated:** 2026-08-05
