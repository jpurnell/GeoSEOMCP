import Testing
import Foundation
@testable import GeoSEOMCP

// MARK: - Syllable Counting Tests

@Suite("Syllable Counting")
struct SyllableCountingTests {

    @Test("Golden path: common words have correct syllable counts")
    func testCommonWords() {
        #expect(countSyllables(in: "hello") == 2)
        #expect(countSyllables(in: "world") == 1)
        #expect(countSyllables(in: "beautiful") == 3)
        #expect(countSyllables(in: "the") == 1)
        #expect(countSyllables(in: "area") == 3)
        #expect(countSyllables(in: "computer") == 3)
        #expect(countSyllables(in: "university") == 5)
        #expect(countSyllables(in: "optimization") == 5)
    }

    @Test("Silent-e words count correctly")
    func testSilentE() {
        #expect(countSyllables(in: "cake") == 1)
        #expect(countSyllables(in: "like") == 1)
        #expect(countSyllables(in: "make") == 1)
        #expect(countSyllables(in: "time") == 1)
    }

    @Test("Single-syllable words")
    func testSingleSyllable() {
        #expect(countSyllables(in: "cat") == 1)
        #expect(countSyllables(in: "dog") == 1)
        #expect(countSyllables(in: "run") == 1)
        #expect(countSyllables(in: "a") == 1)
    }

    @Test("Edge: empty string returns 0")
    func testEmptyString() {
        #expect(countSyllables(in: "") == 0)
    }

    @Test("Passage syllable counting sums word syllables")
    func testPassageSyllables() {
        // "hello world" = 2 + 1 = 3
        let count = countPassageSyllables("hello world")
        #expect(count == 3)
    }

    @Test("Passage syllable counting with empty string")
    func testPassageSyllablesEmpty() {
        #expect(countPassageSyllables("") == 0)
    }
}

// MARK: - Word Counting Tests (NLTokenizer)

@Suite("Word Counting")
struct WordCountingTests {

    @Test("Golden path: simple word counting")
    func testSimpleWordCount() {
        #expect(countWords(in: "hello world") == 2)
        #expect(countWords(in: "one two three four five") == 5)
    }

    @Test("Single word")
    func testSingleWord() {
        #expect(countWords(in: "hello") == 1)
    }

    @Test("Multiple spaces between words")
    func testMultipleSpaces() {
        let count = countWords(in: "hello   world")
        #expect(count == 2)
    }

    @Test("Edge: empty string returns 0")
    func testEmptyString() {
        #expect(countWords(in: "") == 0)
    }

    @Test("Punctuation does not inflate word count")
    func testPunctuation() {
        // "Hello, world!" should be 2 words, not 3
        let count = countWords(in: "Hello, world!")
        #expect(count == 2)
    }

    @Test("Contractions count as expected")
    func testContractions() {
        // NLTokenizer may split "don't" into tokens; count should be reasonable
        let count = countWords(in: "I don't know")
        #expect(count >= 3)
    }
}

// MARK: - Sentence Counting Tests (NLTokenizer)

@Suite("Sentence Counting")
struct SentenceCountingTests {

    @Test("Golden path: multiple sentences")
    func testMultipleSentences() {
        #expect(countSentences(in: "Hello. World! Really?") == 3)
    }

    @Test("Single sentence")
    func testSingleSentence() {
        #expect(countSentences(in: "This is one sentence.") == 1)
    }

    @Test("Abbreviations do not cause false splits")
    func testAbbreviations() {
        #expect(countSentences(in: "Dr. Smith went home.") == 1)
    }

    @Test("Multi-sentence with abbreviations")
    func testMultiSentenceWithAbbreviations() {
        let count = countSentences(in: "The U.S. economy grew. Exports increased.")
        #expect(count == 2)
    }

    @Test("No punctuation treated as one sentence")
    func testNoPunctuation() {
        #expect(countSentences(in: "This has no ending punctuation") == 1)
    }

    @Test("Edge: empty string returns 0")
    func testEmptyString() {
        #expect(countSentences(in: "") == 0)
    }
}

// MARK: - Word Tokenization Tests

@Suite("Word Tokenization")
struct WordTokenizationTests {

    @Test("Tokenize returns individual words")
    func testBasicTokenization() {
        let tokens = tokenizeWords("hello world")
        #expect(tokens.count == 2)
        #expect(tokens[0] == "hello")
        #expect(tokens[1] == "world")
    }

    @Test("Empty string returns empty array")
    func testEmptyString() {
        let tokens = tokenizeWords("")
        #expect(tokens.isEmpty)
    }
}

// MARK: - Paragraph Splitting Tests

@Suite("Paragraph Splitting")
struct ParagraphSplittingTests {

    @Test("Split on double newlines")
    func testDoublNewlineSplit() {
        let text = "First paragraph.\n\nSecond paragraph.\n\nThird paragraph."
        let paragraphs = splitParagraphs(text)
        #expect(paragraphs.count == 3)
    }

    @Test("Single paragraph with no double newlines")
    func testSingleParagraph() {
        let text = "Just one paragraph with a single\nnewline inside."
        let paragraphs = splitParagraphs(text)
        #expect(paragraphs.count == 1)
    }

    @Test("Empty string returns empty array")
    func testEmptyString() {
        let paragraphs = splitParagraphs("")
        #expect(paragraphs.isEmpty)
    }
}

// MARK: - Pronoun Density Tests (NLTagger)

@Suite("Pronoun Density")
struct PronounDensityTests {

    @Test("Golden path: text with pronouns")
    func testWithPronouns() {
        // "I went to my house" — NLTagger tags "I" as pronoun, "my" as determiner
        // So density = 1/5 = 0.2
        let density = pronounDensity(in: "I went to my house")
        #expect(abs(density - 0.2) < 0.15, "Expected ~0.2 pronoun density, got \(density)")
    }

    @Test("No pronouns yields zero density")
    func testNoPronouns() {
        let density = pronounDensity(in: "The cat sat on the mat")
        #expect(density < 0.01, "Expected near-zero pronoun density, got \(density)")
    }

    @Test("She is detected as pronoun")
    func testShePronoun() {
        let count = countPronouns(in: "She said the results were promising")
        #expect(count >= 1, "Expected at least 1 pronoun (She), got \(count)")
    }

    @Test("Edge: empty string returns 0.0")
    func testEmptyString() {
        #expect(pronounDensity(in: "") == 0.0)
    }
}

// MARK: - Definition Pattern Tests

@Suite("Definition Pattern Detection")
struct DefinitionPatternTests {

    @Test("'X is the ...' pattern detected")
    func testIsPattern() {
        #expect(containsDefinitionPattern("SEO is the process of optimizing websites"))
    }

    @Test("'X refers to ...' pattern detected")
    func testRefersToPattern() {
        #expect(containsDefinitionPattern("GEO refers to the practice of optimizing for AI"))
    }

    @Test("'defined as' pattern detected")
    func testDefinedAsPattern() {
        #expect(containsDefinitionPattern("Citability is defined as the likelihood of being cited"))
    }

    @Test("No definition pattern returns false")
    func testNoPattern() {
        #expect(!containsDefinitionPattern("We provide great services to our clients"))
    }

    @Test("Edge: empty string returns false")
    func testEmptyString() {
        #expect(!containsDefinitionPattern(""))
    }
}

// MARK: - Statistical Element Tests

@Suite("Statistical Element Counting")
struct StatisticalElementTests {

    @Test("Golden path: mixed statistical elements")
    func testMixedElements() {
        let count = countStatisticalElements(in: "Revenue grew 25% to $1.2M in 2024")
        // 25% (percentage), $1.2M (currency), 2024 (year) = 3
        #expect(count >= 3)
    }

    @Test("No statistical elements")
    func testNoElements() {
        let count = countStatisticalElements(in: "This is a simple sentence about nothing")
        #expect(count == 0)
    }

    @Test("Percentages detected")
    func testPercentages() {
        let count = countStatisticalElements(in: "Growth was 15% and margins improved 3.5%")
        #expect(count >= 2)
    }

    @Test("Edge: empty string returns 0")
    func testEmptyString() {
        #expect(countStatisticalElements(in: "") == 0)
    }
}

// MARK: - List Structure Detection Tests

@Suite("List Structure Detection")
struct ListStructureTests {

    @Test("Numbered list detected")
    func testNumberedList() {
        let text = "Steps:\n1. First step\n2. Second step\n3. Third step"
        #expect(containsListStructure(text))
    }

    @Test("Bullet list detected")
    func testBulletList() {
        let text = "Features:\n- Feature one\n- Feature two"
        #expect(containsListStructure(text))
    }

    @Test("No list structure returns false")
    func testNoList() {
        #expect(!containsListStructure("This is a plain paragraph with no lists."))
    }

    @Test("Edge: empty string returns false")
    func testEmptyString() {
        #expect(!containsListStructure(""))
    }
}

// MARK: - Flesch Readability Tests

@Suite("Flesch Readability")
struct FleschReadabilityTests {

    @Test("Golden path: known values produce expected score")
    func testKnownValues() {
        // 200 words, 10 sentences, 300 syllables
        // RE = 206.835 - 1.015*(200/10) - 84.6*(300/200)
        //    = 206.835 - 20.3 - 126.9 = 59.635
        let score = fleschReadingEase(totalWords: 200, totalSentences: 10, totalSyllables: 300)
        #expect(abs(score - 59.635) < 0.01)
    }

    @Test("Easy text scores higher")
    func testEasyText() {
        // Short sentences, simple words: 100 words, 10 sentences, 120 syllables
        // RE = 206.835 - 1.015*10 - 84.6*1.2 = 206.835 - 10.15 - 101.52 = 95.165
        let score = fleschReadingEase(totalWords: 100, totalSentences: 10, totalSyllables: 120)
        #expect(score > 90.0)
    }

    @Test("Zero words returns NaN")
    func testZeroWords() {
        let score = fleschReadingEase(totalWords: 0, totalSentences: 5, totalSyllables: 10)
        #expect(score.isNaN)
    }

    @Test("Zero sentences returns NaN")
    func testZeroSentences() {
        let score = fleschReadingEase(totalWords: 100, totalSentences: 0, totalSyllables: 150)
        #expect(score.isNaN)
    }
}

// MARK: - Flesch-Kincaid Grade Level Tests

@Suite("Flesch-Kincaid Grade Level")
struct FleschKincaidTests {

    @Test("Golden path: known values produce expected grade level")
    func testKnownValues() {
        // 200 words, 10 sentences, 300 syllables
        // GL = 0.39*(200/10) + 11.8*(300/200) - 15.59
        //    = 0.39*20 + 11.8*1.5 - 15.59 = 7.8 + 17.7 - 15.59 = 9.91
        let grade = fleschKincaidGradeLevel(totalWords: 200, totalSentences: 10, totalSyllables: 300)
        #expect(abs(grade - 9.91) < 0.01)
    }

    @Test("Zero words returns NaN")
    func testZeroWords() {
        let grade = fleschKincaidGradeLevel(totalWords: 0, totalSentences: 5, totalSyllables: 10)
        #expect(grade.isNaN)
    }

    @Test("Zero sentences returns NaN")
    func testZeroSentences() {
        let grade = fleschKincaidGradeLevel(totalWords: 100, totalSentences: 0, totalSyllables: 150)
        #expect(grade.isNaN)
    }
}

// MARK: - Constants Validation Tests

@Suite("Constants Validation")
struct ConstantsValidationTests {

    @Test("14 AI crawlers defined across 3 tiers")
    func testCrawlerCount() {
        let all = AICrawlerRegistry.allCrawlers
        #expect(all.count == 14)
        #expect(AICrawlerRegistry.tier1Crawlers.count == 5)
        #expect(AICrawlerRegistry.tier2Crawlers.count == 5)
        #expect(AICrawlerRegistry.tier3Crawlers.count == 4)
    }

    @Test("Crawler tiers are correctly assigned")
    func testCrawlerTiers() {
        for crawler in AICrawlerRegistry.tier1Crawlers {
            #expect(crawler.tier == .tier1)
        }
        for crawler in AICrawlerRegistry.tier2Crawlers {
            #expect(crawler.tier == .tier2)
        }
        for crawler in AICrawlerRegistry.tier3Crawlers {
            #expect(crawler.tier == .tier3)
        }
    }

    @Test("GEO composite weights sum to 1.0")
    func testCompositeWeightsSum() {
        let sum = GEOWeights.citability + GEOWeights.brandAuthority +
                  GEOWeights.contentEEAT + GEOWeights.technical +
                  GEOWeights.schema + GEOWeights.platform
        #expect(abs(sum - 1.0) < 1e-10)
    }

    @Test("Citability sub-weights sum to 1.0")
    func testCitabilityWeightsSum() {
        let sum = GEOWeights.answerBlockQuality + GEOWeights.selfContainment +
                  GEOWeights.structuralReadability + GEOWeights.statisticalDensity +
                  GEOWeights.uniquenessSignals
        #expect(abs(sum - 1.0) < 1e-10)
    }

    @Test("Technical SEO sub-weights sum to 1.0")
    func testTechnicalWeightsSum() {
        let sum = GEOWeights.ssrCapability + GEOWeights.metaTags +
                  GEOWeights.crawlability + GEOWeights.securityHeaders +
                  GEOWeights.coreWebVitals + GEOWeights.mobileOptimization +
                  GEOWeights.urlStructure + GEOWeights.serverResponse +
                  GEOWeights.additionalTechnical
        #expect(abs(sum - 1.0) < 1e-10)
    }

    @Test("Brand authority sub-weights sum to 1.0")
    func testBrandWeightsSum() {
        let sum = GEOWeights.youtube + GEOWeights.reddit +
                  GEOWeights.wikipedia + GEOWeights.linkedin +
                  GEOWeights.otherPlatforms
        #expect(abs(sum - 1.0) < 1e-10)
    }

    @Test("AI Visibility sub-weights sum to 1.0")
    func testVisibilityWeightsSum() {
        let sum = GEOWeights.tier1Access + GEOWeights.tier2Access +
                  GEOWeights.noBlanketBlocks + GEOWeights.aiFiles
        #expect(abs(sum - 1.0) < 1e-10)
    }

    @Test("All 5 AI platforms defined")
    func testPlatformCount() {
        #expect(AIPlatform.allCases.count == 5)
    }

    @Test("Content benchmarks cover expected page types")
    func testBenchmarkTypes() {
        let benchmarks = ContentBenchmarks.all
        #expect(benchmarks["homepage"] != nil)
        #expect(benchmarks["blog"] != nil)
        #expect(benchmarks["pillar"] != nil)
        #expect(benchmarks["product"] != nil)
        #expect(benchmarks["service"] != nil)
        #expect(benchmarks["about"] != nil)
        #expect(benchmarks["faq"] != nil)
    }

    @Test("sameAs platforms have correct max points total")
    func testSameAsPlatformsTotal() {
        let total = SameAsPlatforms.all.reduce(0.0) { $0 + $1.maxPoints }
        #expect(abs(total - 15.0) < 1e-10)
    }

    @Test("Security headers have 6 entries totaling 100 points")
    func testSecurityHeaders() {
        #expect(SecurityHeaders.all.count == 6)
        let total = SecurityHeaders.all.reduce(0.0) { $0 + $1.maxPoints }
        #expect(abs(total - 100.0) < 1e-10)
    }

    @Test("Citability grade thresholds are in descending order")
    func testGradeThresholds() {
        #expect(CitabilityConstants.gradeA > CitabilityConstants.gradeB)
        #expect(CitabilityConstants.gradeB > CitabilityConstants.gradeC)
        #expect(CitabilityConstants.gradeC > CitabilityConstants.gradeD)
    }
}
