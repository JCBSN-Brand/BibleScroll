//
//  Verse.swift
//  BibleScroll
//

import Foundation

struct Verse: Identifiable, Codable, Hashable {
    let id: String
    let book: String
    let chapter: Int
    let verseNumber: Int
    let text: String
    
    /// Creates a unique identifier for the verse
    var verseId: String {
        "\(book.lowercased().replacingOccurrences(of: " ", with: "-"))-\(chapter)-\(verseNumber)"
    }
    
    /// Formatted reference string (e.g., "John 3:16")
    var reference: String {
        "\(book) \(chapter):\(verseNumber)"
    }
}

// MARK: - Sample Data for Development
extension Verse {
    static let sampleVerses: [Verse] = [
        Verse(id: "gen-1-1", book: "Genesis", chapter: 1, verseNumber: 1,
              text: "In the beginning God created the heaven and the earth."),
        Verse(id: "gen-1-2", book: "Genesis", chapter: 1, verseNumber: 2,
              text: "And the earth was without form, and void; and darkness was upon the face of the deep. And the Spirit of God moved upon the face of the waters."),
        Verse(id: "gen-1-3", book: "Genesis", chapter: 1, verseNumber: 3,
              text: "And God said, Let there be light: and there was light."),
        Verse(id: "gen-1-4", book: "Genesis", chapter: 1, verseNumber: 4,
              text: "And God saw the light, that it was good: and God divided the light from the darkness."),
        Verse(id: "gen-1-5", book: "Genesis", chapter: 1, verseNumber: 5,
              text: "And God called the light Day, and the darkness he called Night. And the evening and the morning were the first day."),
        Verse(id: "john-3-16", book: "John", chapter: 3, verseNumber: 16,
              text: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life."),
        Verse(id: "john-3-17", book: "John", chapter: 3, verseNumber: 17,
              text: "For God sent not his Son into the world to condemn the world; but that the world through him might be saved."),
        Verse(id: "psalm-23-1", book: "Psalms", chapter: 23, verseNumber: 1,
              text: "The Lord is my shepherd; I shall not want."),
        Verse(id: "psalm-23-2", book: "Psalms", chapter: 23, verseNumber: 2,
              text: "He maketh me to lie down in green pastures: he leadeth me beside the still waters."),
        Verse(id: "psalm-23-3", book: "Psalms", chapter: 23, verseNumber: 3,
              text: "He restoreth my soul: he leadeth me in the paths of righteousness for his name's sake."),
    ]
}


