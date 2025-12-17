//
//  ActionButtonsView.swift
//  BibleScroll
//
//  Like, comment, and share buttons (vertical stack on bottom-right)
//

import SwiftUI

// App Store link for sharing
private let appStoreLink = "https://apps.apple.com/app/scroll-the-bible/id6756558351"

// Fun, catchy hooks that rotate randomly when sharing
private let shareHooks: [String] = [
    "Okay wait, you HAVE to see this 👀",
    "Stop what you're doing. This is actually insane.",
    "I'm not even kidding, this changed everything for me",
    "So I found this and now I can't stop using it",
    "You're gonna thank me for this one",
    "Why did nobody tell me about this sooner?!",
    "This is lowkey the best thing on my phone rn",
    "I know you're busy but PLEASE look at this",
    "Okay but this verse hit different:",
    "Not me getting hooked on a Bible app but HERE WE ARE",
    "No but seriously, you need this in your life",
    "Just trust me on this one 🙏",
    "I literally can't stop scrolling through this",
    "This is the sign you've been waiting for:",
    "POV: You just found your new daily habit",
]

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
        let hook = shareHooks.randomElement() ?? shareHooks[0]
        return "\(hook)\n\n\"\(verse.text)\"\n\n— \(verse.reference)\n\n\(appStoreLink)"
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
