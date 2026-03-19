# Design Proposal: Crawler Access Tools

## 1. Objective

**Objective:** Implement robots.txt parsing and AI crawler access analysis to evaluate how accessible a website is to the 14 AI crawlers across 3 tiers.
**Master Plan Reference:** Phase 2 — Core Analysis (Step 4)

## 2. Tools

### parse_robots_txt
Parse robots.txt content and extract user-agent rules, returning structured data about which paths are allowed/disallowed for each user-agent.

### analyze_ai_crawler_access
Given parsed robots.txt rules, determine which of the 14 AI crawlers are allowed, blocked, or partially restricted. Reports per-tier status.

### calculate_ai_visibility_score
Calculate a weighted visibility score (0-100) based on AI crawler access using tier weights from GEOWeights.

## 3. Algorithm

**Robots.txt Parsing:**
- Parse User-agent, Allow, Disallow directives
- Handle wildcards (*), comments (#), Crawl-delay
- Group rules by user-agent

**Crawler Access Analysis:**
- For each of 14 crawlers, check its user-agent against robots.txt rules
- Also check wildcard (*) rules as fallback
- Status: allowed, blocked, partially_restricted

**Visibility Score:**
- Tier 1 (50% weight): 5 crawlers, each worth 10 points
- Tier 2 (25% weight): 5 crawlers, each worth 5 points
- No blanket blocks (15% weight): 100 if no `Disallow: /` for `*`
- AI-specific files (10% weight): bonus for llms.txt, ai.txt presence

## 4. Test Strategy

- Fully open robots.txt → all 14 allowed, score 100
- Block all GPTBot → Tier 1 reduced
- Blanket `Disallow: /` for `*` → depends on specific user-agent rules
- Empty robots.txt → all allowed (no restrictions)
- Comments and blank lines handled correctly
