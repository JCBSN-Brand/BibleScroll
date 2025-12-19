//
//  APIConfig.swift
//  BibleScroll
//
//  API configuration - Store your API keys here
//
//  SETUP INSTRUCTIONS:
//  1. Copy this file and rename it to "APIConfig.swift"
//  2. Replace the placeholder values with your actual API keys
//  3. APIConfig.swift is gitignored, so your keys stay private
//

import Foundation

/// API Configuration
/// Replace placeholder values with your actual API credentials
enum APIConfig {
    
    // MARK: - API.Bible Configuration
    
    /// Your API.Bible API key
    /// Get yours at: https://scripture.api.bible
    static let apiBibleKey = "YOUR_API_BIBLE_KEY_HERE"
    
    /// API.Bible base URL
    static let apiBibleBaseURL = "https://api.scripture.api.bible/v1"
    
    /// Bible version ID
    /// Common options:
    /// - "de4e12af7f28f599-02" = KJV (King James Version)
    /// - "06125adad2d5898a-01" = ASV (American Standard Version)
    /// - "9879dbb7cfe39e4d-04" = WEB (World English Bible)
    /// - "55212e3cf5d04d49-01" = ESV (requires special permission)
    ///
    /// Find more at: https://scripture.api.bible/livedocs#/Bibles/getBibles
    static let bibleId = "de4e12af7f28f599-02"  // KJV
    
    // MARK: - OpenAI Configuration
    
    /// Your OpenAI API key
    /// Get yours at: https://platform.openai.com/api-keys
    static let openAIKey = "YOUR_OPENAI_API_KEY_HERE"
    
    // MARK: - Optional Auth Configuration (for future use)
    
    /// Your backend URL for user authentication (optional)
    static let authBaseURL = ""
    
    /// App identifier
    static let appBundleId = "com.yourcompany.BibleScroll"
}




