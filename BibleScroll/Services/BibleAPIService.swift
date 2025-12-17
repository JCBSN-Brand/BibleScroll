//
//  BibleAPIService.swift
//  BibleScroll
//
//  Handles both offline KJV and API-based translations
//

import Foundation

/// Protocol for Bible API operations
protocol BibleAPIServiceProtocol {
    func fetchVerses(book: String, chapter: Int, translation: BibleTranslation) async throws -> [Verse]
    func fetchBooks() async throws -> [Book]
}

/// Bible API Service - KJV is offline, NLT/NKJV use API
class BibleAPIService: BibleAPIServiceProtocol {
    
    // MARK: - Configuration
    
    private let baseURL = APIConfig.apiBibleBaseURL
    private let apiKey = APIConfig.apiBibleKey
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    // MARK: - Cache
    
    /// In-memory cache for API-fetched chapters to reduce API calls
    /// Key format: "translation-book-chapter" (e.g., "NLT-Matthew-5")
    private static var verseCache: [String: [Verse]] = [:]
    
    /// Generate cache key for a chapter
    private func cacheKey(translation: BibleTranslation, book: String, chapter: Int) -> String {
        return "\(translation.shortName)-\(book)-\(chapter)"
    }
    
    // MARK: - Book ID Mapping
    
    private let bookIdMap: [String: String] = [
        "Genesis": "GEN", "Exodus": "EXO", "Leviticus": "LEV", "Numbers": "NUM",
        "Deuteronomy": "DEU", "Joshua": "JOS", "Judges": "JDG", "Ruth": "RUT",
        "1 Samuel": "1SA", "2 Samuel": "2SA", "1 Kings": "1KI", "2 Kings": "2KI",
        "1 Chronicles": "1CH", "2 Chronicles": "2CH", "Ezra": "EZR", "Nehemiah": "NEH",
        "Esther": "EST", "Job": "JOB", "Psalms": "PSA", "Proverbs": "PRO",
        "Ecclesiastes": "ECC", "Song of Solomon": "SNG", "Isaiah": "ISA", "Jeremiah": "JER",
        "Lamentations": "LAM", "Ezekiel": "EZK", "Daniel": "DAN", "Hosea": "HOS",
        "Joel": "JOL", "Amos": "AMO", "Obadiah": "OBA", "Jonah": "JON",
        "Micah": "MIC", "Nahum": "NAM", "Habakkuk": "HAB", "Zephaniah": "ZEP",
        "Haggai": "HAG", "Zechariah": "ZEC", "Malachi": "MAL",
        "Matthew": "MAT", "Mark": "MRK", "Luke": "LUK", "John": "JHN",
        "Acts": "ACT", "Romans": "ROM", "1 Corinthians": "1CO", "2 Corinthians": "2CO",
        "Galatians": "GAL", "Ephesians": "EPH", "Philippians": "PHP", "Colossians": "COL",
        "1 Thessalonians": "1TH", "2 Thessalonians": "2TH", "1 Timothy": "1TI", "2 Timothy": "2TI",
        "Titus": "TIT", "Philemon": "PHM", "Hebrews": "HEB", "James": "JAS",
        "1 Peter": "1PE", "2 Peter": "2PE", "1 John": "1JN", "2 John": "2JN",
        "3 John": "3JN", "Jude": "JUD", "Revelation": "REV"
    ]
    
    // MARK: - Initialization
    
    init() {
        self.session = URLSession.shared
        self.decoder = JSONDecoder()
    }
    
    // MARK: - API Methods
    
    /// Fetch verses - uses offline data for KJV, cache or API for others
    func fetchVerses(book: String, chapter: Int, translation: BibleTranslation = .kjv) async throws -> [Verse] {
        // KJV is always offline - instant loading, no API cost
        if translation == .kjv {
            print("📖 Loading KJV \(book) \(chapter) (offline)")
            return KJVBibleData.getVerses(book: book, chapter: chapter)
        }
        
        // Check cache first for non-KJV translations
        let key = cacheKey(translation: translation, book: book, chapter: chapter)
        if let cachedVerses = BibleAPIService.verseCache[key] {
            print("📖 Loading \(translation.shortName) \(book) \(chapter) (cached - no API call)")
            return cachedVerses
        }
        
        // Other translations use API
        guard let bibleId = translation.apiId else {
            return KJVBibleData.getVerses(book: book, chapter: chapter)
        }
        
        let verses = try await fetchFromAPI(book: book, chapter: chapter, bibleId: bibleId, translation: translation)
        
        // Cache the result if we got valid verses
        if !verses.isEmpty {
            BibleAPIService.verseCache[key] = verses
            print("💾 Cached \(translation.shortName) \(book) \(chapter) (\(verses.count) verses)")
        }
        
        return verses
    }
    
    /// Fetch from API.Bible - uses chapter endpoint with text format
    private func fetchFromAPI(book: String, chapter: Int, bibleId: String, translation: BibleTranslation) async throws -> [Verse] {
        guard let bookId = bookIdMap[book] else {
            print("❌ Unknown book: \(book)")
            return KJVBibleData.getVerses(book: book, chapter: chapter)
        }
        
        let chapterId = "\(bookId).\(chapter)"
        // Use text content-type for cleaner parsing
        let endpoint = "\(baseURL)/bibles/\(bibleId)/chapters/\(chapterId)?content-type=text&include-notes=false&include-titles=false&include-chapter-numbers=false&include-verse-numbers=true"
        
        print("📖 Fetching \(translation.shortName) \(book) \(chapter)...")
        
        guard let url = URL(string: endpoint) else {
            print("❌ Invalid URL")
            return KJVBibleData.getVerses(book: book, chapter: chapter)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return KJVBibleData.getVerses(book: book, chapter: chapter)
            }
            
            if httpResponse.statusCode == 401 {
                throw BibleAPIError.httpError(statusCode: 401)
            }
            
            if httpResponse.statusCode == 403 {
                // Fall back to KJV if translation not available
                return KJVBibleData.getVerses(book: book, chapter: chapter)
            }
            
            if httpResponse.statusCode == 404 {
                throw BibleAPIError.httpError(statusCode: 404)
            }
            
            if httpResponse.statusCode != 200 {
                throw BibleAPIError.httpError(statusCode: httpResponse.statusCode)
            }
            
            let apiResponse = try decoder.decode(ChapterHTMLResponse.self, from: data)
            
            // First try text parsing
            var verses = parseVersesFromText(apiResponse.data.content, book: book, chapter: chapter)
            
            // If text parsing fails, try HTML parsing
            if verses.isEmpty {
                verses = parseVersesFromHTML(apiResponse.data.content, book: book, chapter: chapter)
            }
            
            // Fall back to KJV if parsing failed
            if verses.isEmpty {
                return KJVBibleData.getVerses(book: book, chapter: chapter)
            }
            
            print("✅ Loaded \(verses.count) verses (\(translation.shortName))")
            return verses
            
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding error: \(decodingError)")
            throw decodingError
        } catch {
            print("❌ Network error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Parse verses from plain text content with verse numbers
    private func parseVersesFromText(_ text: String, book: String, chapter: Int) -> [Verse] {
        var verses: [Verse] = []
        
        // Clean up the text first
        var cleanText = text
        cleanText = cleanText.replacingOccurrences(of: "¶", with: "")
        cleanText = cleanText.replacingOccurrences(of: "\n", with: " ")
        cleanText = cleanText.replacingOccurrences(of: "\r", with: " ")
        cleanText = cleanText.replacingOccurrences(of: "\t", with: " ")
        
        // Pattern for verse numbers followed by text: [1] text
        let bracketPattern = #"\[(\d+)\]\s*([^\[\]]+?)(?=\[\d+\]|$)"#
        
        if let regex = try? NSRegularExpression(pattern: bracketPattern, options: [.dotMatchesLineSeparators]) {
            let range = NSRange(cleanText.startIndex..., in: cleanText)
            let matches = regex.matches(in: cleanText, options: [], range: range)
            
            for match in matches {
                if let numberRange = Range(match.range(at: 1), in: cleanText),
                   let textRange = Range(match.range(at: 2), in: cleanText) {
                    let verseNumber = Int(cleanText[numberRange]) ?? 0
                    var verseText = String(cleanText[textRange])
                    
                    // Clean up formatting - normalize all whitespace
                    verseText = normalizeWhitespace(verseText)
                    
                    if verseNumber > 0 && !verseText.isEmpty {
                        verses.append(Verse(
                            id: "\(book.lowercased())-\(chapter)-\(verseNumber)",
                            book: book,
                            chapter: chapter,
                            verseNumber: verseNumber,
                            text: verseText
                        ))
                    }
                }
            }
        }
        
        return verses.sorted { $0.verseNumber < $1.verseNumber }
    }
    
    /// Normalize whitespace - collapse multiple spaces into single spaces
    private func normalizeWhitespace(_ text: String) -> String {
        var result = text
        
        // Replace various whitespace characters with regular space
        result = result.replacingOccurrences(of: "\u{00A0}", with: " ")  // Non-breaking space
        result = result.replacingOccurrences(of: "\u{2003}", with: " ")  // Em space
        result = result.replacingOccurrences(of: "\u{2002}", with: " ")  // En space
        result = result.replacingOccurrences(of: "\u{2009}", with: " ")  // Thin space
        
        // Collapse multiple spaces into single space
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        
        // Trim leading/trailing whitespace
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return result
    }
    
    /// Parse verses from HTML - handles multiple API.Bible HTML formats
    private func parseVersesFromHTML(_ html: String, book: String, chapter: Int) -> [Verse] {
        var versesDict: [Int: String] = [:]
        
        // First, try to extract verse spans with data-number attribute
        // Pattern 1: <span data-number="1" class="v ...">text</span>
        let pattern1 = #"<span[^>]*data-number="(\d+)"[^>]*class="v[^"]*"[^>]*>([^<]+)"#
        
        // Pattern 2: <span data-usfm="...\.\d+" ...>text</span> (captures text after verse marker)
        let pattern2 = #"<span[^>]*data-usfm="[^"]*\.(\d+)"[^>]*>([^<]+)"#
        
        // Pattern 3: Look for verse number markers followed by text
        // This handles: <span class="v" data-number="1">1</span> followed by text
        let pattern3 = #"data-number="(\d+)"[^>]*>\d+</span>\s*([^<]+)"#
        
        // Pattern 4: Simple span with verse class containing text
        let pattern4 = #"<span[^>]*class="[^"]*v[^"]*"[^>]*data-number="(\d+)"[^>]*>([^<]+)</span>"#
        
        let patterns = [pattern1, pattern2, pattern3, pattern4]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(html.startIndex..., in: html)
                let matches = regex.matches(in: html, options: [], range: range)
                
                for match in matches {
                    if let numberRange = Range(match.range(at: 1), in: html),
                       let textRange = Range(match.range(at: 2), in: html) {
                        let verseNumber = Int(html[numberRange]) ?? 0
                        var text = String(html[textRange])
                        
                        // Clean up HTML entities and whitespace
                        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
                        text = text.replacingOccurrences(of: "&#160;", with: " ")
                        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if verseNumber > 0 && !text.isEmpty && text != "\(verseNumber)" {
                            // Append to existing text for same verse number (handles split verses)
                            if let existing = versesDict[verseNumber] {
                                versesDict[verseNumber] = existing + " " + text
                            } else {
                                versesDict[verseNumber] = text
                            }
                        }
                    }
                }
            }
        }
        
        // If patterns didn't work, try a more aggressive approach
        if versesDict.isEmpty {
            // Remove all HTML tags except verse markers, then parse
            var cleanedHTML = html
            
            // Look for any number followed by text content
            let aggressivePattern = #">\s*(\d{1,3})\s*</span>([^<]+)"#
            if let regex = try? NSRegularExpression(pattern: aggressivePattern, options: []) {
                let range = NSRange(cleanedHTML.startIndex..., in: cleanedHTML)
                let matches = regex.matches(in: cleanedHTML, options: [], range: range)
                
                for match in matches {
                    if let numberRange = Range(match.range(at: 1), in: cleanedHTML),
                       let textRange = Range(match.range(at: 2), in: cleanedHTML) {
                        let verseNumber = Int(cleanedHTML[numberRange]) ?? 0
                        var text = String(cleanedHTML[textRange])
                        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
                        text = text.replacingOccurrences(of: "&#160;", with: " ")
                        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if verseNumber > 0 && verseNumber <= 200 && !text.isEmpty {
                            if let existing = versesDict[verseNumber] {
                                versesDict[verseNumber] = existing + " " + text
                            } else {
                                versesDict[verseNumber] = text
                            }
                        }
                    }
                }
            }
        }
        
        // Convert dictionary to array of Verse objects
        let verses = versesDict.map { (verseNumber, text) in
            Verse(
                id: "\(book.lowercased())-\(chapter)-\(verseNumber)",
                book: book,
                chapter: chapter,
                verseNumber: verseNumber,
                text: normalizeWhitespace(text)
            )
        }.sorted { $0.verseNumber < $1.verseNumber }
        
        return verses
    }
    
    /// Fetch list of all books
    func fetchBooks() async throws -> [Book] {
        return Book.allBooks
    }
}

// MARK: - API Response Models

struct ChapterHTMLResponse: Codable {
    let data: ChapterHTMLData
    
    struct ChapterHTMLData: Codable {
        let id: String
        let bookId: String
        let number: String
        let reference: String
        let content: String
    }
}


// MARK: - Errors

enum BibleAPIError: Error, LocalizedError {
    case httpError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .httpError(let code): return "HTTP Error: \(code)"
        }
    }
}
