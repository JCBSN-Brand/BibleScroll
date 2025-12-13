//
//  BookPickerView.swift
//  BibleScroll
//
//  Book and chapter selection UI
//

import SwiftUI

struct BookPickerView: View {
    @ObservedObject var viewModel: BibleViewModel
    @Binding var isPresented: Bool
    
    @State private var selectedBook: Book?
    @State private var selectedChapter: Int = 1
    @State private var showingChapters = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showingChapters, let book = selectedBook {
                    // Chapter selection grid
                    chapterGridView(for: book)
                } else {
                    // Search bar (not auto-focused)
                    searchBarView
                    
                    // Book list
                    bookListView
                }
            }
            .background(Color.white)
            .navigationTitle(showingChapters ? (selectedBook?.name ?? "Chapters") : "Select Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if showingChapters {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingChapters = false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Books")
                            }
                            .foregroundColor(.black)
                        }
                    } else {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBarView: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search books...", text: $searchText)
                .font(.system(size: 16))
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    // MARK: - Filtered Books
    
    private var filteredOldTestament: [Book] {
        if searchText.isEmpty {
            return viewModel.oldTestamentBooks
        }
        let query = searchText.lowercased()
        return viewModel.oldTestamentBooks.filter { 
            $0.name.lowercased().contains(query) || $0.id.lowercased().contains(query)
        }
    }
    
    private var filteredNewTestament: [Book] {
        if searchText.isEmpty {
            return viewModel.newTestamentBooks
        }
        let query = searchText.lowercased()
        return viewModel.newTestamentBooks.filter { 
            $0.name.lowercased().contains(query) || $0.id.lowercased().contains(query)
        }
    }
    
    // MARK: - Book List View
    
    private var bookListView: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                // Old Testament
                if !filteredOldTestament.isEmpty {
                    Section {
                        ForEach(filteredOldTestament) { book in
                            bookRow(book)
                        }
                    } header: {
                        sectionHeader("Old Testament")
                    }
                }
                
                // New Testament
                if !filteredNewTestament.isEmpty {
                    Section {
                        ForEach(filteredNewTestament) { book in
                            bookRow(book)
                        }
                    } header: {
                        sectionHeader("New Testament")
                    }
                }
                
                // No results
                if filteredOldTestament.isEmpty && filteredNewTestament.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("No books found")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)
                }
            }
        }
    }
    
    private func bookRow(_ book: Book) -> some View {
        Button(action: {
            selectedBook = book
            withAnimation(.easeInOut(duration: 0.2)) {
                showingChapters = true
            }
        }) {
            HStack {
                Text(book.name)
                    .font(.system(size: 17))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("\(book.chapters) chapters")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemGray6))
    }
    
    // MARK: - Chapter Grid View
    
    private func chapterGridView(for book: Book) -> some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5),
                spacing: 12
            ) {
                ForEach(1...book.chapters, id: \.self) { chapter in
                    Button(action: {
                        selectChapter(book: book, chapter: chapter)
                    }) {
                        Text("\(chapter)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(
                                (book.name == viewModel.currentBook && chapter == viewModel.currentChapter)
                                ? .white : .black
                            )
                            .frame(width: 56, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        (book.name == viewModel.currentBook && chapter == viewModel.currentChapter)
                                        ? Color.black : Color.gray.opacity(0.1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Actions
    
    private func selectChapter(book: Book, chapter: Int) {
        Task {
            await viewModel.loadChapter(book: book.name, chapter: chapter)
            isPresented = false
        }
    }
}

#Preview {
    BookPickerView(
        viewModel: BibleViewModel(),
        isPresented: .constant(true)
    )
}
