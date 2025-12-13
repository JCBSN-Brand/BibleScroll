//
//  NotesSheetView.swift
//  BibleScroll
//
//  Personal notes input for a verse - Auto-saves
//

import SwiftUI
import Combine

struct NotesSheetView: View {
    let verse: Verse
    @Binding var noteText: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Verse reference header
                VStack(spacing: 8) {
                    Text(verse.reference)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(verse.text)
                        .font(.custom("Georgia", size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal)
                }
                .padding(.top, 8)
                
                Divider()
                    .padding(.horizontal)
                
                // Notes text editor
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Your Notes")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // Auto-save indicator
                        Text("Auto-saved")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .padding(.horizontal)
                    
                    TextEditor(text: $noteText)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.08))
                        )
                        .padding(.horizontal)
                        .focused($isTextFieldFocused)
                        .onChange(of: noteText) { _, _ in
                            // Auto-save on every change
                            onSave()
                        }
                }
                
                Spacer()
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // Save one final time and dismiss
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                }
            }
        }
        .onAppear {
            // Focus immediately without delay for instant keyboard
            DispatchQueue.main.async {
                isTextFieldFocused = true
            }
        }
        .interactiveDismissDisabled(false)
        .presentationBackground(.white)
        .onDisappear {
            // Auto-save when sheet is dismissed
            onSave()
        }
    }
}

#Preview {
    NotesSheetView(
        verse: Verse.sampleVerses[0],
        noteText: .constant("This verse reminds me of..."),
        onSave: {}
    )
}
