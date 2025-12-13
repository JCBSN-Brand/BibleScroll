//
//  RedLetterText.swift
//  BibleScroll
//
//  Utility for parsing and rendering red letter (Jesus's words) text
//

import SwiftUI

/// Parses verse text with red letter markers [r]...[/r] and creates an AttributedString
struct RedLetterText {
    
    /// Creates an AttributedString with red coloring for Jesus's words
    /// Text wrapped in [r]...[/r] will be rendered in red
    static func parse(_ text: String, fontSize: CGFloat) -> AttributedString {
        var result = AttributedString()
        
        // If no red letter markers, return plain black text
        guard text.contains("[r]") else {
            var plainText = AttributedString(text)
            plainText.foregroundColor = .black
            plainText.font = .custom("Georgia", size: fontSize)
            return plainText
        }
        
        var remainingText = text
        
        while !remainingText.isEmpty {
            if let redStartRange = remainingText.range(of: "[r]") {
                // Add text before the red marker (black)
                let beforeRed = String(remainingText[..<redStartRange.lowerBound])
                if !beforeRed.isEmpty {
                    var blackPart = AttributedString(beforeRed)
                    blackPart.foregroundColor = .black
                    blackPart.font = .custom("Georgia", size: fontSize)
                    result += blackPart
                }
                
                // Find the closing tag
                let afterOpenTag = String(remainingText[redStartRange.upperBound...])
                if let redEndRange = afterOpenTag.range(of: "[/r]") {
                    // Extract red text
                    let redText = String(afterOpenTag[..<redEndRange.lowerBound])
                    var redPart = AttributedString(redText)
                    redPart.foregroundColor = Color(red: 0.8, green: 0.1, blue: 0.1) // Deep red
                    redPart.font = .custom("Georgia", size: fontSize)
                    result += redPart
                    
                    // Continue with remaining text
                    remainingText = String(afterOpenTag[redEndRange.upperBound...])
                } else {
                    // No closing tag found, treat rest as red
                    var redPart = AttributedString(afterOpenTag)
                    redPart.foregroundColor = Color(red: 0.8, green: 0.1, blue: 0.1)
                    redPart.font = .custom("Georgia", size: fontSize)
                    result += redPart
                    break
                }
            } else {
                // No more red markers, add remaining text as black
                var blackPart = AttributedString(remainingText)
                blackPart.foregroundColor = .black
                blackPart.font = .custom("Georgia", size: fontSize)
                result += blackPart
                break
            }
        }
        
        return result
    }
    
    /// Creates a SwiftUI Text view with red letter formatting
    static func textView(_ text: String, fontSize: CGFloat) -> Text {
        // If no red letter markers, return plain text
        guard text.contains("[r]") else {
            return Text(text)
        }
        
        return Text(parse(text, fontSize: fontSize))
    }
}

