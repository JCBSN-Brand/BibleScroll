//
//  AIStudyView.swift
//  BibleScroll
//
//  AI-powered Bible study drawer - ultra minimalist design
//

import SwiftUI

struct AIStudyView: View {
    let verse: Verse
    @Binding var isPresented: Bool
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    @StateObject private var aiService = AIStudyService()
    @State private var selectedMode: AIStudyMode?
    @State private var showingPaywall = false
    @State private var paywallDetent: PresentationDetent = .large
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let mode = selectedMode {
                    // Results view
                    resultsView(mode: mode)
                } else {
                    // Options selection
                    optionsView
                }
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if selectedMode != nil {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedMode = nil
                                aiService.reset()
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
                        .foregroundColor(.gray)
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallDrawerView(isPresented: $showingPaywall)
                    .presentationDetents([.medium, .large], selection: $paywallDetent)
                    .presentationDragIndicator(.visible)
                    .onDisappear {
                        // Reset to .large for next presentation
                        paywallDetent = .large
                    }
            }
        }
    }
    
    // MARK: - Options View
    
    private var optionsView: some View {
        VStack(spacing: 0) {
            // Verse header
            verseHeader
            
            Divider()
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            
            // Study options
            VStack(spacing: 0) {
                ForEach(AIStudyMode.allCases, id: \.self) { mode in
                    optionRow(mode)
                    
                    if mode != AIStudyMode.allCases.last {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var verseHeader: some View {
        VStack(spacing: 8) {
            Text(verse.reference)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            Text(verse.text)
                .font(.custom("Georgia", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }
    
    private func optionRow(_ mode: AIStudyMode) -> some View {
        Button(action: {
            // Check if user is premium before allowing access
            if subscriptionService.isPremium {
                // Premium user - allow access
                selectedMode = mode
                Task {
                    await aiService.study(verse: verse, mode: mode)
                }
            } else {
                // Non-premium user - show paywall
                showingPaywall = true
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: mode.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 24)
                
                Text(mode.title)
                    .font(.system(size: 17))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Results View
    
    private func resultsView(mode: AIStudyMode) -> some View {
        VStack(spacing: 0) {
            // Mode header
            HStack {
                Image(systemName: mode.icon)
                    .font(.system(size: 16, weight: .medium))
                Text(mode.title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Verse reference
            Text(verse.reference)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Content area
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if aiService.isLoading {
                        loadingView
                    } else if let error = aiService.error {
                        errorView(error)
                    } else if !aiService.response.isEmpty {
                        responseView
                    }
                }
                .padding(20)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            CrownLoadingView(size: 28, tint: .black)
            
            Text("Studying...")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: {
                if let mode = selectedMode {
                    Task {
                        await aiService.study(verse: verse, mode: mode)
                    }
                }
            }) {
                Text("Try Again")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var responseView: some View {
        Text(parseMarkdownBold(aiService.response))
            .font(.system(size: 16))
            .foregroundColor(.black)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Parses **bold** markdown syntax into AttributedString
    private func parseMarkdownBold(_ text: String) -> AttributedString {
        var result = AttributedString()
        var remaining = text
        
        while !remaining.isEmpty {
            // Find the next **
            if let startRange = remaining.range(of: "**") {
                // Add text before **
                let beforeBold = String(remaining[..<startRange.lowerBound])
                if !beforeBold.isEmpty {
                    result += AttributedString(beforeBold)
                }
                
                // Move past the opening **
                remaining = String(remaining[startRange.upperBound...])
                
                // Find closing **
                if let endRange = remaining.range(of: "**") {
                    // Extract bold text
                    let boldText = String(remaining[..<endRange.lowerBound])
                    var boldAttr = AttributedString(boldText)
                    boldAttr.font = .system(size: 16, weight: .bold)
                    result += boldAttr
                    
                    // Move past the closing **
                    remaining = String(remaining[endRange.upperBound...])
                } else {
                    // No closing **, treat as regular text
                    result += AttributedString("**" + remaining)
                    remaining = ""
                }
            } else {
                // No more **, add remaining text
                result += AttributedString(remaining)
                remaining = ""
            }
        }
        
        return result
    }
}

#Preview {
    AIStudyView(
        verse: Verse.sampleVerses[0],
        isPresented: .constant(true)
    )
    .environmentObject(SubscriptionService())
}

