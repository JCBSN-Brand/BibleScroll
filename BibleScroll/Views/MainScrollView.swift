//
//  MainScrollView.swift
//  BibleScroll
//
//  TikTok-style vertical paging scroll view for Bible verses
//

import SwiftUI
import SwiftData

struct MainScrollView: View {
    @ObservedObject var viewModel: BibleViewModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            if viewModel.isLoading {
                // Loading state
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(1.2)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.verses.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No verses found")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Vertical scrolling with snapping
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.verses) { verse in
                            VerseCardView(
                                verse: verse,
                                favoritesViewModel: favoritesViewModel
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
            }
        }
        .background(Color.white)
        .ignoresSafeArea()
        .onAppear {
            favoritesViewModel.setup(with: modelContext)
        }
    }
}

#Preview {
    MainScrollView(viewModel: BibleViewModel())
        .modelContainer(for: [Favorite.self, Note.self], inMemory: true)
}
