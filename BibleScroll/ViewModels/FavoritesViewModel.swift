//
//  FavoritesViewModel.swift
//  BibleScroll
//

import Foundation
import SwiftData

@MainActor
class FavoritesViewModel: ObservableObject {
    
    @Published var favorites: [Favorite] = []
    @Published var favoriteIds: Set<String> = []
    @Published var noteIds: Set<String> = []  // Track verses that have notes
    
    private var storageService: StorageService?
    
    // MARK: - Setup
    
    func setup(with modelContext: ModelContext) {
        self.storageService = StorageService(modelContext: modelContext)
        loadFavorites()
        loadNoteIds()
    }
    
    // MARK: - Favorites
    
    /// Check if a verse is favorited
    func isFavorite(_ verse: Verse) -> Bool {
        return favoriteIds.contains(verse.verseId)
    }
    
    /// Check if a verse ID is favorited
    func isFavorite(verseId: String) -> Bool {
        return favoriteIds.contains(verseId)
    }
    
    /// Toggle favorite status for a verse
    func toggleFavorite(_ verse: Verse) {
        guard let storage = storageService else { return }
        
        let isFavorited = storage.toggleFavorite(verse)
        
        if isFavorited {
            favoriteIds.insert(verse.verseId)
        } else {
            favoriteIds.remove(verse.verseId)
        }
        
        loadFavorites()
    }
    
    /// Load all favorites from storage
    func loadFavorites() {
        guard let storage = storageService else { return }
        
        favorites = storage.getAllFavorites()
        favoriteIds = Set(favorites.map { $0.verseId })
    }
    
    // MARK: - Notes
    
    /// Get note for a verse
    func getNote(verseId: String) -> String? {
        return storageService?.getNote(verseId: verseId)?.content
    }
    
    /// Save note for a verse and update UI immediately
    func saveNote(verseId: String, content: String) {
        storageService?.saveNote(verseId: verseId, content: content)
        
        // Update noteIds to trigger UI refresh
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedContent.isEmpty {
            noteIds.remove(verseId)
        } else {
            noteIds.insert(verseId)
        }
    }
    
    /// Check if verse has a note (uses cached noteIds for instant UI updates)
    func hasNote(verseId: String) -> Bool {
        return noteIds.contains(verseId)
    }
    
    /// Load all note IDs from storage
    func loadNoteIds() {
        guard let storage = storageService else { return }
        noteIds = Set(storage.getAllNoteIds())
    }
}
