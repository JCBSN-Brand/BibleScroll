//
//  Note.swift
//  BibleScroll
//

import Foundation
import SwiftData

@Model
final class Note {
    var verseId: String
    var content: String
    var dateModified: Date
    
    init(verseId: String, content: String, dateModified: Date = Date()) {
        self.verseId = verseId
        self.content = content
        self.dateModified = dateModified
    }
}


