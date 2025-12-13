//
//  StorageService.swift
//  BibleScroll
//

import Foundation
import SwiftData

/// Service for managing local storage of favorites and notes
@MainActor
class StorageService: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Favorites
    
    /// Check if a verse is favorited
    func isFavorite(verseId: String) -> Bool {
        let descriptor = FetchDescriptor<Favorite>(
            predicate: #Predicate { $0.verseId == verseId }
        )
        
        do {
            let count = try modelContext.fetchCount(descriptor)
            return count > 0
        } catch {
            print("Error checking favorite: \(error)")
            return false
        }
    }
    
    /// Add a verse to favorites
    func addFavorite(_ verse: Verse) {
        let favorite = Favorite(from: verse)
        modelContext.insert(favorite)
        save()
    }
    
    /// Remove a verse from favorites
    func removeFavorite(verseId: String) {
        let descriptor = FetchDescriptor<Favorite>(
            predicate: #Predicate { $0.verseId == verseId }
        )
        
        do {
            let favorites = try modelContext.fetch(descriptor)
            for favorite in favorites {
                modelContext.delete(favorite)
            }
            save()
        } catch {
            print("Error removing favorite: \(error)")
        }
    }
    
    /// Toggle favorite status for a verse
    func toggleFavorite(_ verse: Verse) -> Bool {
        if isFavorite(verseId: verse.verseId) {
            removeFavorite(verseId: verse.verseId)
            return false
        } else {
            addFavorite(verse)
            return true
        }
    }
    
    /// Get all favorites
    func getAllFavorites() -> [Favorite] {
        let descriptor = FetchDescriptor<Favorite>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching favorites: \(error)")
            return []
        }
    }
    
    // MARK: - Notes
    
    /// Get note for a verse
    func getNote(verseId: String) -> Note? {
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.verseId == verseId }
        )
        
        do {
            let notes = try modelContext.fetch(descriptor)
            return notes.first
        } catch {
            print("Error fetching note: \(error)")
            return nil
        }
    }
    
    /// Save or update a note for a verse
    func saveNote(verseId: String, content: String) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existingNote = getNote(verseId: verseId) {
            // If content is empty, delete the existing note
            if trimmedContent.isEmpty {
                modelContext.delete(existingNote)
            } else {
                existingNote.content = content
                existingNote.dateModified = Date()
            }
            save()
        } else {
            // Only create a new note if content is not empty
            if !trimmedContent.isEmpty {
                let note = Note(verseId: verseId, content: content)
                modelContext.insert(note)
                save()
            }
        }
    }
    
    /// Delete a note
    func deleteNote(verseId: String) {
        if let note = getNote(verseId: verseId) {
            modelContext.delete(note)
            save()
        }
    }
    
    /// Check if verse has a note
    func hasNote(verseId: String) -> Bool {
        guard let note = getNote(verseId: verseId) else { return false }
        return !note.content.isEmpty
    }
    
    /// Get all verse IDs that have notes
    func getAllNoteIds() -> [String] {
        let descriptor = FetchDescriptor<Note>()
        
        do {
            let notes = try modelContext.fetch(descriptor)
            return notes.filter { !$0.content.isEmpty }.map { $0.verseId }
        } catch {
            print("Error fetching note IDs: \(error)")
            return []
        }
    }
    
    // MARK: - Private
    
    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

