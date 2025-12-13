//
//  ActionButtonsView.swift
//  BibleScroll
//
//  Like, comment, and share buttons (vertical stack on middle-right)
//

import SwiftUI

// Lightning fast pop button style
struct FastPopButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

struct ActionButtonsView: View {
    let verse: Verse
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    let onNoteTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Like/Favorite button
            Button(action: {
                favoritesViewModel.toggleFavorite(verse)
            }) {
                Image(favoritesViewModel.isFavorite(verse) ? "bxs-heart" : "bx-heart")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundColor(favoritesViewModel.isFavorite(verse) ? .red : .black)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    )
            }
            .buttonStyle(FastPopButtonStyle())
            
            // Notes/Comment button
            Button(action: {
                onNoteTap()
            }) {
                Image(favoritesViewModel.hasNote(verseId: verse.verseId) ? "bxs-message" : "bx-message")
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
            .buttonStyle(FastPopButtonStyle())
            
            // Share button
            ShareLink(item: shareText) {
                Image("bx-send")
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
            .buttonStyle(FastPopButtonStyle())
        }
    }
    
    private var shareText: String {
        "\"\(verse.text)\"\n\n— \(verse.reference)"
    }
}

#Preview {
    ActionButtonsView(
        verse: Verse.sampleVerses[0],
        favoritesViewModel: FavoritesViewModel(),
        onNoteTap: {}
    )
    .padding()
    .background(Color.white)
}
