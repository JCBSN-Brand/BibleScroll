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
    
    /// Fetch verses - uses offline data for KJV, API for others
    func fetchVerses(book: String, chapter: Int, translation: BibleTranslation = .kjv) async throws -> [Verse] {
        // KJV is always offline - instant loading
        if translation == .kjv {
            print("📖 Loading KJV \(book) \(chapter) (offline)")
            return KJVBibleData.getVerses(book: book, chapter: chapter)
        }
        
        // Other translations use API
        guard let bibleId = translation.apiId else {
            return KJVBibleData.getVerses(book: book, chapter: chapter)
        }
        
        return try await fetchFromAPI(book: book, chapter: chapter, bibleId: bibleId, translation: translation)
    }
    
    /// Fetch from API.Bible
    private func fetchFromAPI(book: String, chapter: Int, bibleId: String, translation: BibleTranslation) async throws -> [Verse] {
        guard let bookId = bookIdMap[book] else {
            print("❌ Unknown book: \(book)")
            return KJVBibleData.getVerses(book: book, chapter: chapter)
        }
        
        let chapterId = "\(bookId).\(chapter)"
        let endpoint = "\(baseURL)/bibles/\(bibleId)/chapters/\(chapterId)?content-type=html&include-notes=false&include-titles=false&include-chapter-numbers=false&include-verse-numbers=true"
        
        print("📖 Fetching \(translation.shortName) \(book) \(chapter) from API...")
        
        guard let url = URL(string: endpoint) else {
            return KJVBibleData.getVerses(book: book, chapter: chapter)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response")
                return KJVBibleData.getVerses(book: book, chapter: chapter)
            }
            
            if httpResponse.statusCode != 200 {
                print("❌ API Error: \(httpResponse.statusCode)")
                if let errorBody = String(data: data, encoding: .utf8) {
                    print("   \(errorBody.prefix(200))")
                }
                return KJVBibleData.getVerses(book: book, chapter: chapter)
            }
            
            let apiResponse = try decoder.decode(ChapterHTMLResponse.self, from: data)
            let verses = parseVersesFromHTML(apiResponse.data.content, book: book, chapter: chapter)
            
            if verses.isEmpty {
                return KJVBibleData.getVerses(book: book, chapter: chapter)
            }
            
            print("✅ Loaded \(verses.count) verses from \(translation.shortName)")
            return verses
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            return KJVBibleData.getVerses(book: book, chapter: chapter)
        }
    }
    
    /// Parse verses from HTML
    private func parseVersesFromHTML(_ html: String, book: String, chapter: Int) -> [Verse] {
        var verses: [Verse] = []
        
        let pattern = #"data-number="(\d+)"[^>]*class="v[^"]*"[^>]*>([^<]+)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return verses
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        
        for match in matches {
            if let numberRange = Range(match.range(at: 1), in: html),
               let textRange = Range(match.range(at: 2), in: html) {
                let verseNumber = Int(html[numberRange]) ?? 0
                let text = String(html[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if verseNumber > 0 && !text.isEmpty {
                    verses.append(Verse(
                        id: "\(book.lowercased())-\(chapter)-\(verseNumber)",
                        book: book,
                        chapter: chapter,
                        verseNumber: verseNumber,
                        text: text
                    ))
                }
            }
        }
        
        return verses.sorted { $0.verseNumber < $1.verseNumber }
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
    case invalidURL
    case invalidResponse
    case invalidBook(String)
    case httpError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .invalidBook(let book): return "Unknown book: \(book)"
        case .httpError(let code): return "HTTP Error: \(code)"
        }
    }
}
