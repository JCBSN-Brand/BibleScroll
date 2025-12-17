//
//  AIStudyService.swift
//  BibleScroll
//
//  OpenAI integration for AI-powered Bible study features
//

import Foundation

enum AIStudyMode: String, CaseIterable {
    case explainEasier = "explain"
    case deeperStudy = "deeper"
    case relatedVerses = "related"
    
    var title: String {
        switch self {
        case .explainEasier: return "Explain Easier"
        case .deeperStudy: return "Deeper Study"
        case .relatedVerses: return "Related Verses"
        }
    }
    
    var icon: String {
        switch self {
        case .explainEasier: return "lightbulb"
        case .deeperStudy: return "book"
        case .relatedVerses: return "link"
        }
    }
    
    func systemPrompt(for verse: Verse) -> String {
        switch self {
        case .explainEasier:
            return """
            You are a helpful Bible teacher who explains Scripture in simple, easy-to-understand terms.
            Explain this verse in plain, modern language that anyone can understand.
            Keep your explanation concise (2-3 paragraphs max).
            Focus on the core meaning and practical application.
            """
        case .deeperStudy:
            return """
            You are a knowledgeable Biblical scholar providing in-depth study notes.
            Provide a deeper study of this verse including:
            - Historical and cultural context
            - Original Hebrew/Greek word meanings if relevant
            - Theological significance
            - How this connects to the broader Biblical narrative
            Keep it informative but readable (3-4 paragraphs max).
            """
        case .relatedVerses:
            return """
            You are a Bible cross-reference expert.
            Provide 5-7 related Bible verses that connect to this verse thematically.
            For each verse:
            - Include the full reference (Book Chapter:Verse)
            - Include the verse text (KJV)
            - Briefly explain the connection (1 sentence)
            Format as a clean list.
            """
        }
    }
}

class AIStudyService: ObservableObject {
    @Published var isLoading = false
    @Published var response: String = ""
    @Published var error: String?
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init() {
        self.apiKey = APIConfig.openAIKey
    }
    
    func study(verse: Verse, mode: AIStudyMode) async {
        await MainActor.run {
            isLoading = true
            response = ""
            error = nil
        }
        
        guard !apiKey.isEmpty else {
            await MainActor.run {
                error = "OpenAI API key not configured"
                isLoading = false
            }
            return
        }
        
        // Always use KJV text for AI features (public domain, no copyright restrictions)
        // This ensures compliance with API.Bible terms regarding AI usage of copyrighted content
        let kjvText = getKJVText(for: verse)
        let userMessage = "\(verse.reference) (KJV): \"\(kjvText)\""
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": mode.systemPrompt(for: verse)],
                ["role": "user", "content": userMessage]
            ],
            "max_tokens": 800,
            "temperature": 0.7
        ]
        
        guard let url = URL(string: baseURL) else {
            await MainActor.run {
                error = "Invalid URL"
                isLoading = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            await MainActor.run {
                self.error = "Failed to encode request"
                isLoading = false
            }
            return
        }
        
        do {
            let (data, httpResponse) = try await URLSession.shared.data(for: request)
            
            guard let response = httpResponse as? HTTPURLResponse else {
                await MainActor.run {
                    self.error = "Invalid response"
                    isLoading = false
                }
                return
            }
            
            if response.statusCode != 200 {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorDict = errorJson["error"] as? [String: Any],
                   let message = errorDict["message"] as? String {
                    await MainActor.run {
                        self.error = message
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.error = "API error: \(response.statusCode)"
                        isLoading = false
                    }
                }
                return
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                await MainActor.run {
                    self.error = "Failed to parse response"
                    isLoading = false
                }
                return
            }
            
            await MainActor.run {
                self.response = content.trimmingCharacters(in: .whitespacesAndNewlines)
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func reset() {
        response = ""
        error = nil
        isLoading = false
    }
    
    /// Get KJV text for a verse (public domain - safe for AI usage)
    /// This ensures compliance with API.Bible copyright terms
    private func getKJVText(for verse: Verse) -> String {
        // Fetch KJV text from offline data
        let kjvVerses = KJVBibleData.getVerses(book: verse.book, chapter: verse.chapter)
        
        // Find matching verse number
        if let kjvVerse = kjvVerses.first(where: { $0.verseNumber == verse.verseNumber }) {
            return kjvVerse.text
        }
        
        // Fallback to the verse text if KJV not found (shouldn't happen)
        return verse.text
    }
}

