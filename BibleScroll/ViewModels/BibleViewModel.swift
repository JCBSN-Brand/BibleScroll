//
//  BibleViewModel.swift
//  BibleScroll
//

import Foundation
import SwiftUI

@MainActor
class BibleViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var verses: [Verse] = []
    @Published var currentVerseIndex: Int = 0
    @Published var currentBook: String = "Genesis"
    @Published var currentChapter: Int = 1
    @Published var currentTranslation: BibleTranslation = .kjv
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // MARK: - Services
    
    private let apiService: BibleAPIService
    
    // MARK: - Computed Properties
    
    var currentVerse: Verse? {
        guard currentVerseIndex >= 0 && currentVerseIndex < verses.count else {
            return nil
        }
        return verses[currentVerseIndex]
    }
    
    var books: [Book] {
        Book.allBooks
    }
    
    var oldTestamentBooks: [Book] {
        Book.oldTestament
    }
    
    var newTestamentBooks: [Book] {
        Book.newTestament
    }
    
    // MARK: - Initialization
    
    init(apiService: BibleAPIService = BibleAPIService()) {
        self.apiService = apiService
        
        // Load initial chapter
        Task {
            await loadChapter(book: currentBook, chapter: currentChapter)
        }
    }
    
    // MARK: - Public Methods
    
    /// Load verses for a specific book and chapter
    func loadChapter(book: String, chapter: Int) async {
        isLoading = true
        error = nil
        
        do {
            let fetchedVerses = try await apiService.fetchVerses(book: book, chapter: chapter, translation: currentTranslation)
            
            self.verses = fetchedVerses
            self.currentBook = book
            self.currentChapter = chapter
            self.currentVerseIndex = 0
            self.isLoading = false
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
    
    /// Change translation and reload current chapter
    func setTranslation(_ translation: BibleTranslation) async {
        currentTranslation = translation
        await loadChapter(book: currentBook, chapter: currentChapter)
    }
    
    /// Navigate to next chapter
    func nextChapter() async {
        guard let currentBookData = books.first(where: { $0.name == currentBook }) else { return }
        
        if currentChapter < currentBookData.chapters {
            // Next chapter in same book
            await loadChapter(book: currentBook, chapter: currentChapter + 1)
        } else {
            // Move to next book
            if let currentIndex = books.firstIndex(where: { $0.name == currentBook }),
               currentIndex < books.count - 1 {
                let nextBook = books[currentIndex + 1]
                await loadChapter(book: nextBook.name, chapter: 1)
            }
        }
    }
    
    /// Navigate to previous chapter
    func previousChapter() async {
        if currentChapter > 1 {
            // Previous chapter in same book
            await loadChapter(book: currentBook, chapter: currentChapter - 1)
        } else {
            // Move to previous book (last chapter)
            if let currentIndex = books.firstIndex(where: { $0.name == currentBook }),
               currentIndex > 0 {
                let previousBook = books[currentIndex - 1]
                await loadChapter(book: previousBook.name, chapter: previousBook.chapters)
            }
        }
    }
    
    /// Get number of chapters for a book
    func chaptersCount(for bookName: String) -> Int {
        return books.first(where: { $0.name == bookName })?.chapters ?? 1
    }
    
    /// Jump to a specific verse index
    func goToVerse(_ index: Int) {
        guard index >= 0 && index < verses.count else { return }
        currentVerseIndex = index
    }
    
    /// Update current verse index when user scrolls
    func updateCurrentVerse(to index: Int) {
        currentVerseIndex = index
    }
}

