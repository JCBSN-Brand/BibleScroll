//
//  NotesListView.swift
//  BibleScroll
//
//  View for displaying all saved notes/comments
//

import SwiftUI
import SwiftData

struct NotesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Note.dateModified, order: .reverse) private var notes: [Note]
    
    @State private var showingClearConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var noteToDelete: Note?
    
    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
            }
            .background(Color.white)
            .navigationTitle("My Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
                
                if !notes.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Clear All") {
                            showingClearConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("Clear All Notes?", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllNotes()
                }
            } message: {
                Text("This will permanently delete all your notes. This action cannot be undone.")
            }
            .alert("Delete Note?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    noteToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let note = noteToDelete {
                        deleteNote(note)
                    }
                    noteToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this note?")
            }
        }
    }
    
    // MARK: - Actions
    
    private func clearAllNotes() {
        withAnimation {
            for note in notes {
                modelContext.delete(note)
            }
            try? modelContext.save()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image("bx-message")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No notes yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
            
            Text("Tap the message icon on any verse to add a note")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Notes List
    
    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(notes) { note in
                    noteCard(note)
                }
            }
            .padding(20)
        }
    }
    
    private func noteCard(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Verse reference
            Text(formatVerseId(note.verseId))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black)
            
            // Note content
            Text(note.content)
                .font(.system(size: 15))
                .foregroundColor(.black.opacity(0.8))
                .lineSpacing(4)
            
            HStack {
                // Date
                Text(formatDate(note.dateModified))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Delete button
                Button(action: {
                    noteToDelete = note
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    // MARK: - Helpers
    
    private func formatVerseId(_ verseId: String) -> String {
        // Convert "genesis-24-1" to "Genesis 24:1"
        let parts = verseId.split(separator: "-")
        if parts.count >= 3 {
            let book = parts[0].prefix(1).uppercased() + parts[0].dropFirst()
            let chapter = parts[1]
            let verse = parts[2]
            return "\(book) \(chapter):\(verse)"
        }
        return verseId
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func deleteNote(_ note: Note) {
        withAnimation(.easeOut(duration: 0.2)) {
            modelContext.delete(note)
        }
    }
}

#Preview {
    NotesListView()
        .modelContainer(for: [Favorite.self, Note.self], inMemory: true)
}

