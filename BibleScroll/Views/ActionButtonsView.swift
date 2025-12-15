//
//  ActionButtonsView.swift
//  BibleScroll
//
//  Like, comment, and share buttons (vertical stack on bottom-right)
//

import SwiftUI

// App Store link for sharing - UPDATE THIS when app is live
private let appStoreLink = "YOUR_APP_STORE_LINK_HERE"

// Button style used by action buttons and crown button
struct FastPopButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ActionButtonsView: View {
    let verse: Verse
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    let onNoteTap: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Like/Favorite button
            Button(action: {
                favoritesViewModel.toggleFavorite(verse)
            }) {
                actionButtonLabel(
                    imageName: favoritesViewModel.isFavorite(verse) ? "bxs-heart" : "bx-heart",
                    tint: favoritesViewModel.isFavorite(verse) ? .red : .black
                )
            }
            .buttonStyle(FastPopButtonStyle())
            
            // Notes/Comment button
            Button(action: {
                onNoteTap()
            }) {
                actionButtonLabel(
                    imageName: favoritesViewModel.hasNote(verseId: verse.verseId) ? "bxs-message" : "bx-message",
                    tint: .black
                )
            }
            .buttonStyle(FastPopButtonStyle())
            
            // Share button
            ShareLink(item: shareText) {
                actionButtonLabel(
                    imageName: "bx-send",
                    tint: .black
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func actionButtonLabel(imageName: String, tint: Color) -> some View {
        Image(imageName)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
            .foregroundColor(tint)
            .padding(13)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
    }
    
    private var shareText: String {
        "\"\(verse.text)\"\n\n— \(verse.reference)\n\nFrom Bible Scroll app\n\(appStoreLink)"
    }
}

#Preview {
    ActionButtonsView(
        verse: Verse.sampleVerses[0],
        favoritesViewModel: FavoritesViewModel(),
        onNoteTap: {}
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
