//
//  KJVBibleData.swift
//  BibleScroll
//
//  Loads KJV Bible data from bundled JSON file - complete offline access
//

import Foundation

/// Provides offline KJV Bible verse data from bundled JSON
enum KJVBibleData {
    
    // MARK: - Cached Data
    
    private static var cachedBible: KJVBible?
    
    /// Load and cache the Bible data
    private static func loadBible() -> KJVBible? {
        if let cached = cachedBible {
            return cached
        }
        
        guard let url = Bundle.main.url(forResource: "kjv", withExtension: "json") else {
            print("❌ Could not find kjv.json in bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let bible = try JSONDecoder().decode(KJVBible.self, from: data)
            cachedBible = bible
            print("✅ Loaded KJV Bible: \(bible.books.count) books")
            return bible
        } catch {
            print("❌ Error loading KJV JSON: \(error)")
            return nil
        }
    }
    
    // MARK: - Public API
    
    /// Get verses for a specific book and chapter
    static func getVerses(book: String, chapter: Int) -> [Verse] {
        guard let bible = loadBible() else {
            return [placeholderVerse(book: book, chapter: chapter)]
        }
        
        guard let bookData = bible.books[book] else {
            print("⚠️ Book not found: \(book)")
            return [placeholderVerse(book: book, chapter: chapter)]
        }
        
        guard let chapterData = bookData.chapters[String(chapter)] else {
            print("⚠️ Chapter not found: \(book) \(chapter)")
            return [placeholderVerse(book: book, chapter: chapter)]
        }
        
        // Convert dictionary to sorted array of verses
        var verses: [Verse] = []
        
        for (verseNumStr, text) in chapterData.verses {
            guard let verseNum = Int(verseNumStr) else { continue }
            
            verses.append(Verse(
                id: "\(book.lowercased().replacingOccurrences(of: " ", with: "-"))-\(chapter)-\(verseNum)",
                book: book,
                chapter: chapter,
                verseNumber: verseNum,
                text: text
            ))
        }
        
        // Sort by verse number
        return verses.sorted { $0.verseNumber < $1.verseNumber }
    }
    
    /// Get all book names
    static func getAllBooks() -> [String] {
        guard let bible = loadBible() else { return [] }
        return Array(bible.books.keys)
    }
    
    /// Check if a book exists
    static func hasBook(_ book: String) -> Bool {
        guard let bible = loadBible() else { return false }
        return bible.books[book] != nil
    }
    
    /// Get chapter count for a book
    static func chapterCount(for book: String) -> Int {
        guard let bible = loadBible(),
              let bookData = bible.books[book] else { return 0 }
        return bookData.chapters.count
    }
    
    // MARK: - Private
    
    private static func placeholderVerse(book: String, chapter: Int) -> Verse {
        Verse(
            id: "\(book.lowercased())-\(chapter)-1",
            book: book,
            chapter: chapter,
            verseNumber: 1,
            text: "Unable to load verse. Please try again."
        )
    }
}

// MARK: - JSON Models

struct KJVBible: Codable {
    let translation: String
    let name: String
    let description: String
    let books: [String: KJVBook]
}

struct KJVBook: Codable {
    let name: String
    let testament: String
    let chapters: [String: KJVChapter]
}

struct KJVChapter: Codable {
    let verses: [String: String]
}
