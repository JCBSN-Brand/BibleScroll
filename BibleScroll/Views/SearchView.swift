//
//  SearchView.swift
//  BibleScroll
//
//  Search for any book, chapter, or verse
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: BibleViewModel
    @Binding var isPresented: Bool
    
    @State private var searchText = ""
    @State private var selectedBook: Book?
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let book = selectedBook {
                    // Show chapter selection for selected book
                    chapterSelectionView(for: book)
                } else {
                    // Show search bar and results
                    searchBarView
                    
                    if searchText.isEmpty {
                        allBooksView
                    } else {
                        searchResultsView
                    }
                }
            }
            .background(Color.white)
            .navigationTitle(selectedBook?.name ?? "Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if selectedBook != nil {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedBook = nil
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Back")
                            }
                            .foregroundColor(.black)
                        }
                    } else {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .foregroundColor(.black)
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                isSearchFocused = true
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
                .focused($isSearchFocused)
            
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
    
    // MARK: - Chapter Selection View
    
    private func chapterSelectionView(for book: Book) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Book info header
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.testament.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    Text("\(book.chapters) Chapters")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Chapter grid
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
                                .foregroundColor(.black)
                                .frame(width: 56, height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - All Books View
    
    private var allBooksView: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                Section {
                    ForEach(Book.oldTestament) { book in
                        bookRow(book)
                    }
                } header: {
                    sectionHeader("Old Testament")
                }
                
                Section {
                    ForEach(Book.newTestament) { book in
                        bookRow(book)
                    }
                } header: {
                    sectionHeader("New Testament")
                }
            }
        }
    }
    
    // MARK: - Search Results
    
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredBooks) { book in
                    bookRow(book)
                }
                
                if filteredBooks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("No results found")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)
                }
            }
        }
    }
    
    private var filteredBooks: [Book] {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        
        return Book.allBooks.filter { book in
            let bookName = book.name.lowercased()
            
            if bookName.contains(query) || bookName.hasPrefix(query) {
                return true
            }
            
            if book.id.lowercased().contains(query) {
                return true
            }
            
            return false
        }
    }
    
    // MARK: - UI Components
    
    private func bookRow(_ book: Book) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedBook = book
                isSearchFocused = false
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
    
    // MARK: - Actions
    
    private func selectChapter(book: Book, chapter: Int) {
        Task {
            await viewModel.loadChapter(book: book.name, chapter: chapter)
            isPresented = false
        }
    }
}

#Preview {
    SearchView(
        viewModel: BibleViewModel(),
        isPresented: .constant(true)
    )
}
