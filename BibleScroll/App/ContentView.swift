//
//  ContentView.swift
//  BibleScroll
//

import SwiftUI
import SwiftData

// MARK: - Reusable Header Button Styles
struct HeaderCircleButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .padding(11)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HeaderCapsuleButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentView: View {
    @StateObject private var viewModel = BibleViewModel()
    @State private var showingBookPicker = false
    @State private var showingFavorites = false
    @State private var showingNotes = false
    @State private var showingSearch = false
    @State private var showingTranslation = false
    @State private var selectedTranslation: BibleTranslation = .kjv
    
    // Tutorial state - persisted with @AppStorage
    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial = false
    @State private var showingTutorial = false
    
    var body: some View {
        Group {
            if showingTutorial {
                // Full-screen tutorial for first-time users
                TutorialView(isShowingTutorial: $showingTutorial)
                    .transition(.opacity)
            } else {
                // Main app content
                mainContent
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            // Show tutorial on first launch
            if !hasCompletedTutorial {
                showingTutorial = true
            }
        }
        .onChange(of: showingTutorial) { _, isShowing in
            if !isShowing {
                // Mark tutorial as completed when dismissed
                hasCompletedTutorial = true
            }
        }
    }
    
    // MARK: - Main Content View
    private var mainContent: some View {
        GeometryReader { geometry in
            ZStack {
                // Pure white background
                Color.white
                    .ignoresSafeArea()
                
                MainScrollView(viewModel: viewModel)
                
                // TEMPORARY: Reset tutorial button for testing
                VStack {
                    Spacer()
                    Button(action: {
                        hasCompletedTutorial = false
                        showingTutorial = true
                    }) {
                        Text("Reset Tutorial")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.red)
                                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.bottom, 50)
                }
                
                // Navigation bar - positioned at top with proper safe area
                VStack(spacing: 0) {
                    // Header content
                    HStack(spacing: 6) {
                        // Left group: Search + Translation
                        HStack(spacing: 5) {
                            // Search button
                            HeaderCircleButton(action: { showingSearch = true }) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            
                            // Translation selector
                            HeaderCircleButton(action: { showingTranslation = true }) {
                                Text(selectedTranslation.shortName)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }
                        
                        Spacer(minLength: 2)
                        
                        // Center: Book/Chapter picker
                        HeaderCapsuleButton(action: { showingBookPicker = true }) {
                            HStack(spacing: 3) {
                                Text(viewModel.currentBook)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                Text("\(viewModel.currentChapter)")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.black)
                        }
                        
                        Spacer(minLength: 2)
                        
                        // Right group: Notes + Favorites
                        HStack(spacing: 5) {
                            // Notes button
                            HeaderCircleButton(action: { showingNotes = true }) {
                                Image("bxs-message")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(.black)
                            }
                            
                            // Favorites button
                            HeaderCircleButton(action: { showingFavorites = true }) {
                                Image("bxs-heart")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .frame(maxWidth: geometry.size.width)
                    .padding(.horizontal, 10)
                    .padding(.top, geometry.safeAreaInsets.top + 6)
                    .padding(.bottom, 6)
                    
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Favorite.self, Note.self], inMemory: true)
}
