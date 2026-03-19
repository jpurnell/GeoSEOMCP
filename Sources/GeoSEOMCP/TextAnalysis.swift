import Foundation
import NaturalLanguage

// MARK: - NL-Powered Tokenization

/// Count words using NLTokenizer(.word).
/// Handles contractions, abbreviations, and Unicode correctly.
/// - Parameter text: The text to count words in.
/// - Returns: Number of words, or 0 for empty text.
public func countWords(in text: String) -> Int {
    guard !text.isEmpty else { return 0 }
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = text
    var count = 0
    tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { _, _ in
        count += 1
        return true
    }
    return count
}

/// Count sentences using NLTokenizer(.sentence).
/// Handles abbreviations like "Dr." and "U.S." without false splits.
/// - Parameter text: The text to count sentences in.
/// - Returns: Number of sentences, or 0 for empty text.
public func countSentences(in text: String) -> Int {
    guard !text.isEmpty else { return 0 }
    let tokenizer = NLTokenizer(unit: .sentence)
    tokenizer.string = text
    var count = 0
    tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { _, _ in
        count += 1
        return true
    }
    return count
}

/// Extract all word tokens from text using NLTokenizer(.word).
/// - Parameter text: The text to tokenize.
/// - Returns: Array of word strings.
public func tokenizeWords(_ text: String) -> [String] {
    guard !text.isEmpty else { return [] }
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = text
    var tokens: [String] = []
    tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
        tokens.append(String(text[range]))
        return true
    }
    return tokens
}

/// Split text into paragraphs (double-newline separated).
/// - Parameter text: The text to split.
/// - Returns: Array of non-empty paragraph strings.
public func splitParagraphs(_ text: String) -> [String] {
    guard !text.isEmpty else { return [] }
    return text.components(separatedBy: "\n\n")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}

// MARK: - NL-Powered Part-of-Speech Analysis

/// Count pronouns in text using NLTagger(.lexicalClass).
/// - Parameter text: The text to analyze.
/// - Returns: Number of pronoun tokens.
public func countPronouns(in text: String) -> Int {
    guard !text.isEmpty else { return 0 }
    let tagger = NLTagger(tagSchemes: [.lexicalClass])
    tagger.string = text
    var count = 0
    tagger.enumerateTags(
        in: text.startIndex..<text.endIndex,
        unit: .word,
        scheme: .lexicalClass,
        options: [.omitPunctuation, .omitWhitespace]
    ) { tag, _ in
        if tag == .pronoun {
            count += 1
        }
        return true
    }
    return count
}

/// Calculate pronoun density using NLTagger(.lexicalClass).
/// - Parameter text: The text to analyze.
/// - Returns: Ratio of pronoun count to total word count, or 0.0 for empty text.
public func pronounDensity(in text: String) -> Double {
    guard !text.isEmpty else { return 0.0 }
    let words = countWords(in: text)
    guard words > 0 else { return 0.0 }
    let pronouns = countPronouns(in: text)
    return Double(pronouns) / Double(words)
}

// MARK: - Syllable Counting (Custom Heuristic)

/// Count syllables in a single English word using a vowel-group heuristic
/// with adjustments for silent-e, common suffixes, and hiatus patterns.
/// - Parameter word: A single word to count syllables for.
/// - Returns: Number of syllables, minimum 1 for non-empty words, 0 for empty string.
public func countSyllables(in word: String) -> Int {
    let lower = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    guard !lower.isEmpty else { return 0 }

    let vowels: Set<Character> = ["a", "e", "i", "o", "u", "y"]
    let chars = Array(lower)

    // Step 1: Count vowel groups (consecutive vowels = 1 group)
    var count = 0
    var previousWasVowel = false
    for char in chars {
        let isVowel = vowels.contains(char)
        if isVowel && !previousWasVowel {
            count += 1
        }
        previousWasVowel = isVowel
    }

    // Step 2: Silent-e at end of word (not "le")
    if lower.hasSuffix("e") && !lower.hasSuffix("le") && count > 1 {
        count -= 1
    }

    // Step 3: Add syllables for hiatus patterns where adjacent vowels
    // are in separate syllables. Only add when both vowels are in the
    // same vowel group (i.e., they were counted as 1 in step 1).
    let hiatusPairs: Set<String> = [
        "ia", "iu", "ua", "uo",
        "eo", "ea",
    ]
    // Digraphs that are always one syllable (override hiatus)
    let diphthongs: Set<String> = [
        "eau", "eai",
    ]
    for i in 0..<(chars.count - 1) {
        if vowels.contains(chars[i]) && vowels.contains(chars[i + 1]) {
            let pair = String([chars[i], chars[i + 1]])
            if hiatusPairs.contains(pair) {
                // Check if part of a longer digraph that shouldn't split
                var skipHiatus = false
                if i + 2 < chars.count {
                    let trigraph = String([chars[i], chars[i + 1], chars[i + 2]])
                    if diphthongs.contains(trigraph) {
                        skipHiatus = true
                    }
                }
                if !skipHiatus {
                    count += 1
                }
            }
        }
    }

    return max(count, 1)
}

/// Count total syllables in a text passage.
/// Tokenizes with NLTokenizer(.word), then sums per-word syllable counts.
/// - Parameter text: The passage to count syllables in.
/// - Returns: Total syllable count, or 0 for empty text.
public func countPassageSyllables(_ text: String) -> Int {
    let words = tokenizeWords(text)
    return words.reduce(0) { $0 + countSyllables(in: $1) }
}

// MARK: - Content Pattern Detection

/// Check if text contains a definition pattern.
/// Detects: "X is the ...", "X is a ...", "X refers to ...", "X means ...", "defined as ...".
/// - Parameter text: The text to check.
/// - Returns: `true` if a definition pattern is found.
public func containsDefinitionPattern(_ text: String) -> Bool {
    guard !text.isEmpty else { return false }
    let patterns = [
        #"\b\w+\s+is\s+(?:the|a|an)\s+"#,
        #"\brefers?\s+to\b"#,
        #"\bmeans?\s+"#,
        #"\bdefined\s+as\b"#,
        #"\bknown\s+as\b"#,
    ]
    for pattern in patterns {
        if text.range(of: pattern, options: .regularExpression, range: nil, locale: nil) != nil {
            return true
        }
    }
    return false
}

/// Count statistical elements in text: percentages, currency amounts, years, numeric data.
/// - Parameter text: The text to analyze.
/// - Returns: Number of statistical elements found.
public func countStatisticalElements(in text: String) -> Int {
    guard !text.isEmpty else { return 0 }
    var count = 0
    let patterns = [
        #"\d+\.?\d*%"#,                   // Percentages: 25%, 3.5%
        #"\$[\d,.]+[KMBTkmbt]?"#,         // Currency: $1.2M, $500
        #"\b(19|20)\d{2}\b"#,             // Years: 2024, 1999
        #"\b\d{1,3}(,\d{3})+\b"#,         // Large numbers: 1,000,000
    ]
    for pattern in patterns {
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(text.startIndex..., in: text)
            count += regex.numberOfMatches(in: text, range: range)
        }
    }
    return count
}

/// Detect if text contains list structures (bullets or numbered items).
/// - Parameter text: The text to check.
/// - Returns: `true` if list structures are found.
public func containsListStructure(_ text: String) -> Bool {
    guard !text.isEmpty else { return false }
    let patterns = [
        #"(?m)^\s*\d+[\.\)]\s+"#,         // Numbered: "1. ", "2) "
        #"(?m)^\s*[-•*]\s+"#,             // Bullets: "- ", "• ", "* "
    ]
    for pattern in patterns {
        if text.range(of: pattern, options: .regularExpression) != nil {
            return true
        }
    }
    return false
}

// MARK: - Readability Formulas

/// Calculate Flesch Reading Ease score.
///
/// Formula: `206.835 - 1.015 × (words/sentences) - 84.6 × (syllables/words)`
///
/// - Parameters:
///   - totalWords: Total word count.
///   - totalSentences: Total sentence count.
///   - totalSyllables: Total syllable count.
/// - Returns: Flesch Reading Ease score, or `.nan` if words or sentences is zero.
public func fleschReadingEase(totalWords: Int, totalSentences: Int, totalSyllables: Int) -> Double {
    guard totalWords > 0, totalSentences > 0 else { return .nan }
    let wordsPerSentence = Double(totalWords) / Double(totalSentences)
    let syllablesPerWord = Double(totalSyllables) / Double(totalWords)
    return 206.835 - 1.015 * wordsPerSentence - 84.6 * syllablesPerWord
}

/// Calculate Flesch-Kincaid Grade Level.
///
/// Formula: `0.39 × (words/sentences) + 11.8 × (syllables/words) - 15.59`
///
/// - Parameters:
///   - totalWords: Total word count.
///   - totalSentences: Total sentence count.
///   - totalSyllables: Total syllable count.
/// - Returns: Grade level, or `.nan` if words or sentences is zero.
public func fleschKincaidGradeLevel(totalWords: Int, totalSentences: Int, totalSyllables: Int) -> Double {
    guard totalWords > 0, totalSentences > 0 else { return .nan }
    let wordsPerSentence = Double(totalWords) / Double(totalSentences)
    let syllablesPerWord = Double(totalSyllables) / Double(totalWords)
    return 0.39 * wordsPerSentence + 11.8 * syllablesPerWord - 15.59
}
