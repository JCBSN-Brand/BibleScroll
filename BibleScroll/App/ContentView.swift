//
//  ContentView.swift
//  BibleScroll
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = BibleViewModel()
    @State private var showingBookPicker = false
    @State private var showingFavorites = false
    @State private var showingNotes = false
    @State private var showingSearch = false
    @State private var showingTranslation = false
    @State private var selectedTranslation: BibleTranslation = .kjv
    
    var body: some View {
        ZStack {
            // Pure white background
            Color.white
                .ignoresSafeArea()
            
            MainScrollView(viewModel: viewModel)
            
            // Navigation bar
            VStack {
                HStack(spacing: 8) {
                    // Left side: Search button
                    Button(action: {
                        showingSearch = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                            )
                    }
                    
                    // Translation selector
                    Button(action: {
                        showingTranslation = true
                    }) {
                        Text(selectedTranslation.shortName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                            )
                    }
                    
                    Spacer()
                    
                    // Center: Book/Chapter picker
                    Button(action: {
                        showingBookPicker = true
                    }) {
                        HStack(spacing: 6) {
                            Text(viewModel.currentBook)
                                .font(.system(size: 16, weight: .medium))
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Text("\(viewModel.currentChapter)")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                        )
                    }
                    .frame(maxWidth: 160)
                    
                    Spacer()
                    
                    // Right side: Notes button
                    Button(action: {
                        showingNotes = true
                    }) {
                        Image("bxs-message")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .foregroundColor(.black)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                            )
                    }
                    
                    // Favorites button
                    Button(action: {
                        showingFavorites = true
                    }) {
                        Image("bxs-heart")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .foregroundColor(.black)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingBookPicker) {
            BookPickerView(viewModel: viewModel, isPresented: $showingBookPicker)
        }
        .sheet(isPresented: $showingFavorites) {
            FavoritesView()
        }
        .sheet(isPresented: $showingNotes) {
            NotesListView()
        }
        .sheet(isPresented: $showingSearch) {
            SearchView(viewModel: viewModel, isPresented: $showingSearch)
        }
        .sheet(isPresented: $showingTranslation) {
            TranslationPickerView(isPresented: $showingTranslation, selectedTranslation: $selectedTranslation)
                .presentationDetents([.medium])
        }
        .onChange(of: selectedTranslation) { _, newTranslation in
            Task {
                await viewModel.setTranslation(newTranslation)
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Favorite.self, Note.self], inMemory: true)
}
