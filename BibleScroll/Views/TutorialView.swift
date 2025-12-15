//
//  TutorialView.swift
//  BibleScroll
//
//  Scroll-based tutorial for first-time users - styled like verses
//

import SwiftUI

// MARK: - Tutorial Card Model
struct TutorialCard: Identifiable {
    let id = UUID()
    let mainText: String
    let subtitleText: String
    let buttonDemo: TutorialButtonDemo?
}

enum TutorialButtonDemo {
    case like
    case notes
    case share
    case crown
    case bookPicker
    case translation
    case favorites
    case notesHeader
    case search
}

// MARK: - Tutorial View
struct TutorialView: View {
    @Binding var isShowingTutorial: Bool
    @State private var currentPage = 0
    @State private var hasScrolled = false
    @State private var showScrollHint = true
    
    private let cards: [TutorialCard] = [
        TutorialCard(
            mainText: "Welcome to Bible Scroll.",
            subtitleText: "Let's take a quick tour to help you get the most out of your Bible reading.",
            buttonDemo: nil
        ),
        TutorialCard(
            mainText: "Swipe up to explore verses one at a time, just like this.",
            subtitleText: "Each verse fills the screen so you can focus on God's Word.",
            buttonDemo: nil
        ),
        TutorialCard(
            mainText: "Save your favorite verses by tapping the heart.",
            subtitleText: "Double-tap anywhere on a verse for a quick like!",
            buttonDemo: .like
        ),
        TutorialCard(
            mainText: "Add personal reflections and study notes to any verse.",
            subtitleText: "Your thoughts will be saved and easy to find later.",
            buttonDemo: .notes
        ),
        TutorialCard(
            mainText: "Share inspiring verses with friends and family.",
            subtitleText: "Spread God's Word with those you love.",
            buttonDemo: .share
        ),
        TutorialCard(
            mainText: "Tap the crown for AI-powered Bible study.",
            subtitleText: "Get context, cross-references, and deeper insights.",
            buttonDemo: .crown
        ),
        TutorialCard(
            mainText: "Jump to any book and chapter in the Bible.",
            subtitleText: "Navigate Scripture with ease.",
            buttonDemo: .bookPicker
        ),
        TutorialCard(
            mainText: "View your saved verses and notes anytime.",
            subtitleText: "Build your personal collection of meaningful passages.",
            buttonDemo: .favorites
        ),
        TutorialCard(
            mainText: "You're all set!",
            subtitleText: "Start exploring God's Word.",
            buttonDemo: nil
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // White background
                Color.white
                    .ignoresSafeArea()
                
                // Scrollable tutorial cards
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                            TutorialCardView(
                                card: card,
                                isLastCard: index == cards.count - 1,
                                onComplete: completeTutorial
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { _ in
                            if !hasScrolled {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    hasScrolled = true
                                    showScrollHint = false
                                }
                            }
                        }
                )
                
                // Scroll hint on first page
                if showScrollHint {
                    VStack {
                        Spacer()
                        ScrollHintView()
                            .padding(.bottom, 80)
                    }
                    .transition(.opacity)
                }
            }
        }
    }
    
    private func completeTutorial() {
        withAnimation(.easeOut(duration: 0.3)) {
            isShowingTutorial = false
        }
    }
}

// MARK: - Tutorial Card View (styled like verse)
struct TutorialCardView: View {
    let card: TutorialCard
    let isLastCard: Bool
    let onComplete: () -> Void
    
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            Color.white
            
            VStack(spacing: 24) {
                Spacer()
                
                // Button demo (if applicable) - shown above text
                if let demo = card.buttonDemo {
                    TutorialButtonDemoView(demo: demo)
                        .padding(.bottom, 20)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: animateIn)
                }
                
                // Main text (styled exactly like verse text - Georgia font)
                Text(card.mainText)
                    .font(.custom("Georgia", size: dynamicFontSize(for: card.mainText)))
                    .fontWeight(.regular)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 15)
                    .animation(.easeOut(duration: 0.4), value: animateIn)
                
                // Subtitle (styled exactly like verse reference - gray with tracking)
                Text(card.subtitleText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .tracking(1)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)
                
                // Get Started button on last card
                if isLastCard {
                    Button(action: onComplete) {
                        Text("Get Started")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color.black)
                            )
                    }
                    .padding(.top, 30)
                    .opacity(animateIn ? 1 : 0)
                    .scaleEffect(animateIn ? 1 : 0.9)
                    .animation(.easeOut(duration: 0.4).delay(0.3), value: animateIn)
                }
                
                Spacer()
            }
        }
        .onAppear {
            // Slight delay to trigger animation after view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateIn = true
            }
        }
        .onDisappear {
            animateIn = false
        }
    }
    
    private func dynamicFontSize(for text: String) -> CGFloat {
        let length = text.count
        if length > 80 {
            return 22
        } else if length > 50 {
            return 24
        } else {
            return 26
        }
    }
}

// MARK: - Tutorial Button Demo View
struct TutorialButtonDemoView: View {
    let demo: TutorialButtonDemo
    
    var body: some View {
        switch demo {
        case .like:
            LikeButtonDemo()
        case .notes:
            NotesButtonDemo()
        case .share:
            ShareButtonDemo()
        case .crown:
            CrownButtonDemo()
        case .bookPicker:
            BookPickerDemo()
        case .favorites:
            FavoritesDemo()
        case .translation:
            TranslationDemo()
        case .notesHeader:
            NotesHeaderDemo()
        case .search:
            SearchDemo()
        }
    }
}

// MARK: - Button Demos
struct LikeButtonDemo: View {
    @State private var isLiked = false
    @State private var showHeart = false
    
    var body: some View {
        Button(action: {
            isLiked.toggle()
            if isLiked {
                // Show heart animation
                showHeart = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showHeart = false
                }
            }
            // Haptic
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }) {
            ZStack {
                Image(isLiked ? "bxs-heart" : "bx-heart")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .foregroundColor(isLiked ? .red : .black)
                    .padding(18)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)
                    )
                    .scaleEffect(isLiked ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isLiked)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotesButtonDemo: View {
    @State private var hasNote = false
    
    var body: some View {
        Button(action: {
            hasNote.toggle()
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }) {
            Image(hasNote ? "bxs-message" : "bx-message")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .foregroundColor(.black)
                .padding(18)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShareButtonDemo: View {
    var body: some View {
        Image("bx-send")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 28, height: 28)
            .foregroundColor(.black)
            .padding(18)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)
            )
    }
}

struct CrownButtonDemo: View {
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Image("crown-icon")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 60, height: 60)
            .foregroundColor(.black)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)
            )
            .scaleEffect(scale)
            .onAppear {
                // Subtle pulse animation
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    scale = 1.05
                }
            }
    }
}

struct BookPickerDemo: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Genesis")
                .font(.system(size: 14, weight: .medium))
            Text("1")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.gray)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.gray)
        }
        .foregroundColor(.black)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
        )
    }
}

struct FavoritesDemo: View {
    var body: some View {
        HStack(spacing: 12) {
            // Notes button
            Image("bxs-message")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(.black)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                )
            
            // Favorites button
            Image("bxs-heart")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(.black)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                )
        }
    }
}

struct TranslationDemo: View {
    var body: some View {
        Text("KJV")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.black)
            .padding(12)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
            )
    }
}

struct NotesHeaderDemo: View {
    var body: some View {
        Image("bxs-message")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
            .foregroundColor(.black)
            .padding(12)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
            )
    }
}

struct SearchDemo: View {
    var body: some View {
        Image(systemName: "magnifyingglass")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.black)
            .padding(12)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
            )
    }
}

// MARK: - Scroll Hint View
struct ScrollHintView: View {
    @State private var animating = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chevron.up")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.gray.opacity(0.6))
                .offset(y: animating ? -8 : 0)
            
            Text("Swipe up to continue")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray.opacity(0.6))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animating = true
            }
        }
    }
}

#Preview {
    TutorialView(isShowingTutorial: .constant(true))
}
