//
//  FavoritesView.swift
//  BibleScroll
//
//  View for displaying saved/favorited verses
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Favorite.dateAdded, order: .reverse) private var favorites: [Favorite]
    
    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    emptyStateView
                } else {
                    favoritesList
                }
            }
            .background(Color.white)
            .navigationTitle("Saved Verses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image("bx-heart")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No saved verses yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
            
            Text("Tap the heart icon on any verse to save it here")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Favorites List
    
    private var favoritesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(favorites) { favorite in
                    favoriteCard(favorite)
                }
            }
            .padding(20)
        }
    }
    
    private func favoriteCard(_ favorite: Favorite) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Verse text
            Text(favorite.text)
                .font(.custom("Georgia", size: 16))
                .foregroundColor(.black)
                .lineSpacing(4)
            
            HStack {
                // Reference
                Text("\(favorite.bookName) \(favorite.chapter):\(favorite.verseNumber)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Delete button
                Button(action: {
                    deleteFavorite(favorite)
                }) {
                    Image("bxs-heart")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    // MARK: - Actions
    
    private func deleteFavorite(_ favorite: Favorite) {
        withAnimation(.easeOut(duration: 0.2)) {
            modelContext.delete(favorite)
        }
    }
}

#Preview {
    FavoritesView()
        .modelContainer(for: [Favorite.self, Note.self], inMemory: true)
}


