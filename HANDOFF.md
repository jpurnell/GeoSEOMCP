# Handoff: GeoSEO MCP

**Date:** 2026-08-26
**Status:** Quality gate passing (0 errors, 0 warnings, 40 of 45 checkers). Upstream PR still pending.

## Current Session (2026-08-26)

Cleared two quality-gate findings. Full detail in
`05_SUMMARIES/05_01_FIX_SUMMARIES/2026-08-26_CRLFSafetyAndDocCCatalogue.md`.

1. **`safety` error** — `parseRobotsTxt` split on `CharacterSet.newlines`, which treats a
   CRLF as two separators. Now splits on `\.isNewline`. No behaviour change; the parser
   already skipped the empty elements. Only occurrence in the package.

2. **`doc-lint` error (pre-existing)** — the package had no DocC catalogue, so the doc
   checkers had nothing to examine and reported that as a failure. Added
   `Sources/GeoSEOMCP/GeoSEOMCP.docc/GeoSEOMCP.md`: 84 public symbols curated into 12
   topic sections, all links resolving. This also cleared a 52-occurrence
   `doc-lint.no-coverage` consistency cluster (score 0.75 → 1.00).

**Do not "simplify" `resources: [.copy("GeoSEOMCP.docc")]` out of `Package.swift`.** It
looks redundant but is not — see the Context Loss Warning in the session summary.

## What Needs To Happen Next

### Submit Upstream PR

The fix is ready at `/tmp/swift-sdk-fix` — **verify this still exists**, `/tmp` does not
survive reboots. If it is gone, the branch is pushed at `jpurnell/swift-sdk`.

```bash
cd /tmp/swift-sdk-fix
git log --oneline -1
# e61c613 Fix SendingRisksDataRace in NetworkTransport for Swift 6.3+

gh pr create \
  --repo modelcontextprotocol/swift-sdk \
  --head jpurnell:fix/swift6-sending-data-race \
  --title "Fix SendingRisksDataRace in NetworkTransport for Swift 6.3+" \
  --body "..."
```

### After Upstream Merge: Revert to Official URL

1. **GeoSEOMCP** `Package.swift`:
   ```swift
   // Change:
   .package(url: "https://github.com/jpurnell/swift-sdk.git", exact: "0.10.3"),
   // Back to:
   .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "<merged-version>"),
   ```

2. **SwiftMCPServer** `Package.swift`:
   ```swift
   // Change:
   .package(url: "https://github.com/jpurnell/swift-sdk.git", "0.10.0"..<"0.11.0"),
   // Back to:
   .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "<merged-version>"),
   ```

3. Tag a new SwiftMCPServer release, update GeoSEOMCP's pin accordingly.

### Open Planning Questions

`project/master_plan.md` still carries three `[NEEDS INPUT]` markers: Priorities, the
Roadmap (specifically a maintenance story for the crawler registry, which is the part most
exposed to outside change), and whether the `Ignite` structured-data work and this
server's schema analysis are meant to be one pipeline.

### Deployment Note — Resolved

roseclub.org runs **Swift 6.3.3** (confirmed 2026-08-26). This clears the blocker the
2026-05-16 handoff raised: that handoff recorded the server at 6.0.3 and flagged the
`swift-tools-version` bump to 6.2 as needing a server toolchain update first. The server
has since been updated, 6.3.3 satisfies the 6.2 requirement, and **there is no deployment
blocker**. The 6.0.3 figure is historical — disregard it.

Toolchain drift is still real and still worth a check each deploy: local is 6.4, server is
6.3.3. That gap is what the `jpurnell/swift-sdk` fork exists to bridge — the
`SendingRisksDataRace` fix is what makes a clean build possible under 6.3's stricter
concurrency checking.

```bash
ssh roseclub.org "swift --version"
```

## File Locations

| Item | Path |
|------|------|
| GeoSEOMCP | `/Users/jpurnell/Dropbox/Computer/Development/Swift/Tools/GeoSEOMCP` |
| SwiftMCPServer | `/Users/jpurnell/Dropbox/Computer/Development/Swift/Tools/SwiftMCPServer` |
| swift-sdk fork (local) | `/tmp/swift-sdk-fix` |
| swift-sdk fork (remote) | `https://github.com/jpurnell/swift-sdk` |
| Quality gate config | `.quality-gate.yml` |
| Session summaries | `05_SUMMARIES/05_01_FIX_SUMMARIES/` |
