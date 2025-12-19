//
//  Favorite.swift
//  BibleScroll
//

import Foundation
import SwiftData

@Model
final class Favorite {
    var verseId: String
    var bookName: String
    var chapter: Int
    var verseNumber: Int
    var text: String
    var dateAdded: Date
    
    init(verseId: String, bookName: String, chapter: Int, verseNumber: Int, text: String, dateAdded: Date = Date()) {
        self.verseId = verseId
        self.bookName = bookName
        self.chapter = chapter
        self.verseNumber = verseNumber
        self.text = text
        self.dateAdded = dateAdded
    }
    
    /// Create a Favorite from a Verse
    convenience init(from verse: Verse) {
        self.init(
            verseId: verse.verseId,
            bookName: verse.book,
            chapter: verse.chapter,
            verseNumber: verse.verseNumber,
            text: verse.text
        )
    }
}





