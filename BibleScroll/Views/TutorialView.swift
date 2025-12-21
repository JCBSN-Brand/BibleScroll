//
//  TutorialView.swift
//  BibleScroll
//
//  Scroll-based tutorial for first-time users - styled like verses
//

import SwiftUI
import StoreKit

// MARK: - Tutorial Card Model
struct TutorialCard: Identifiable {
    let id = UUID()
    let mainText: String
    let subtitleText: String
    let buttonDemo: TutorialButtonDemo?
    let isPaywall: Bool
    let isReviewRequest: Bool
    let isShareRequest: Bool
    
    init(mainText: String, subtitleText: String, buttonDemo: TutorialButtonDemo? = nil, isPaywall: Bool = false, isReviewRequest: Bool = false, isShareRequest: Bool = false) {
        self.mainText = mainText
        self.subtitleText = subtitleText
        self.buttonDemo = buttonDemo
        self.isPaywall = isPaywall
        self.isReviewRequest = isReviewRequest
        self.isShareRequest = isShareRequest
    }
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
    
    // Paywall state - kept at TutorialView level to persist across re-renders
    @State private var paywallSelectedPlan: PaywallView.SubscriptionPlan = .yearly
    @State private var paywallWithFreeTrial: Bool = false
    @State private var paywallIsPurchasing: Bool = false
    
    private let cards: [TutorialCard] = [
        TutorialCard(
            mainText: "Welcome to Scroll The Bible.",
            subtitleText: "Let's take a quick tour to help you get the most out of your Bible reading."
        ),
        TutorialCard(
            mainText: "Swipe up to explore verses one at a time, just like this.",
            subtitleText: "Each verse fills the screen so you can focus on God's Word."
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
        // Paywall card
        TutorialCard(
            mainText: "",
            subtitleText: "",
            isPaywall: true
        ),
        // Review request card
        TutorialCard(
            mainText: "",
            subtitleText: "",
            isReviewRequest: true
        ),
        // Share request card
        TutorialCard(
            mainText: "",
            subtitleText: "",
            isShareRequest: true
        ),
        TutorialCard(
            mainText: "You're all set!",
            subtitleText: "Start exploring God's Word."
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
                    VStack(spacing: 0) {
                        ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                            if card.isPaywall {
                                // iOS 18 and below: use minHeight to prevent clipping
                                // iOS 26+: use fixed height (works perfectly)
                                if #available(iOS 26, *) {
                                    PaywallView(
                                        onComplete: completeTutorial,
                                        selectedPlan: $paywallSelectedPlan,
                                        withFreeTrial: $paywallWithFreeTrial,
                                        isPurchasing: $paywallIsPurchasing
                                    )
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                } else {
                                    PaywallView(
                                        onComplete: completeTutorial,
                                        selectedPlan: $paywallSelectedPlan,
                                        withFreeTrial: $paywallWithFreeTrial,
                                        isPurchasing: $paywallIsPurchasing
                                    )
                                    .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: geometry.size.height)
                                }
                            } else if card.isReviewRequest {
                                ReviewRequestCardView()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            } else if card.isShareRequest {
                                ShareRequestCardView()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            } else {
                                TutorialCardView(
                                    card: card,
                                    cardIndex: index,
                                    isLastCard: index == cards.count - 1,
                                    onComplete: completeTutorial
                                )
                                .frame(width: geometry.size.width, height: geometry.size.height)
                            }
                        }
                        
                        // Exit trigger page - completes tutorial when scrolled into view
                        TutorialExitTrigger(onTrigger: completeTutorial)
                            .frame(width: geometry.size.width, height: geometry.size.height)
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
    // Static tracking to survive view recreation during app lifecycle
    private static var animatedCardIDs: Set<String> = []
    // Track cards that have COMPLETED their animation (not just started)
    private static var completedAnimationCardIDs: Set<String> = []
    
    let card: TutorialCard
    let cardIndex: Int
    let isLastCard: Bool
    let onComplete: () -> Void
    
    @State private var animateIn = false
    
    // Unique key for this card that's stable across view recreations
    private var cardKey: String {
        "tutorial-card-\(cardIndex)"
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700
            
            ZStack {
                Color.white
                
                VStack(spacing: isCompact ? 18 : 24) {
                    Spacer()
                    
                    // Button demo (if applicable) - shown above text
                    if let demo = card.buttonDemo {
                        TutorialButtonDemoView(demo: demo, isCompact: isCompact)
                            .padding(.bottom, isCompact ? 14 : 20)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: animateIn)
                    }
                    
                    // Main text (styled exactly like verse text - Georgia font)
                    Text(card.mainText)
                        .font(.custom("Georgia", size: dynamicFontSize(for: card.mainText, isCompact: isCompact)))
                        .fontWeight(.regular)
                        .multilineTextAlignment(.center)
                        .lineSpacing(isCompact ? 4 : 6)
                        .foregroundColor(.black)
                        .padding(.horizontal, isCompact ? 20 : 24)
                        .frame(maxWidth: .infinity)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 15)
                        .animation(.easeOut(duration: 0.4), value: animateIn)
                    
                    // Subtitle (styled exactly like verse reference - gray with tracking)
                    Text(card.subtitleText)
                        .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .multilineTextAlignment(.center)
                        .lineSpacing(isCompact ? 3 : 4)
                        .padding(.horizontal, isCompact ? 30 : 40)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)
                    
                    Spacer()
                    
                    // Scroll hint on last card
                    if isLastCard {
                        LastCardScrollHint()
                            .padding(.bottom, isCompact ? 60 : 80)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.3), value: animateIn)
                    }
                }
            }
        }
        .onAppear {
            // For the first card: if animation already completed, show immediately (no re-animation)
            if cardIndex == 0 && Self.completedAnimationCardIDs.contains(cardKey) {
                animateIn = true
                return
            }
            
            // Check if animation is already in progress (prevents double-scheduling)
            guard !Self.animatedCardIDs.contains(cardKey) else { return }
            Self.animatedCardIDs.insert(cardKey)
            
            // Longer delay for first card to ensure app is fully loaded before animation starts
            let delay: Double = cardIndex == 0 ? 0.6 : 0.1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                animateIn = true
                // Mark first card as having completed its animation
                if cardIndex == 0 {
                    Self.completedAnimationCardIDs.insert(cardKey)
                }
            }
        }
        .onDisappear {
            animateIn = false
            // Remove from in-progress tracking
            Self.animatedCardIDs.remove(cardKey)
            // Note: completedAnimationCardIDs is NOT cleared - first card stays "completed"
        }
    }
    
    // Static method to reset animation tracking (call when tutorial completes)
    static func resetAnimationTracking() {
        animatedCardIDs.removeAll()
        completedAnimationCardIDs.removeAll()
    }
    
    private func dynamicFontSize(for text: String, isCompact: Bool) -> CGFloat {
        let length = text.count
        let baseSize: CGFloat = isCompact ? 20 : 26
        if length > 80 {
            return baseSize - 4
        } else if length > 50 {
            return baseSize - 2
        } else {
            return baseSize
        }
    }
}

// MARK: - Review Request Card View
struct ReviewRequestCardView: View {
    // Static tracking to survive view recreation during app lifecycle
    private static var hasAnimated = false
    
    @Environment(\.requestReview) private var requestReview
    @AppStorage("hasLeftReview") private var hasLeftReview = false
    @State private var animateIn = false
    @State private var reviewState: ReviewState = .idle
    @State private var crownScale: CGFloat = 1.0
    
    enum ReviewState {
        case idle
        case loading
        case completed
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700
            
            ZStack {
                Color.white
                
                VStack(spacing: isCompact ? 24 : 32) {
                    Spacer()
                    
                    // Icon area - shows star initially, crown during loading, checkmark when complete
                    ZStack {
                        // Star icon (idle state)
                        Image(systemName: "star.fill")
                            .font(.system(size: isCompact ? 44 : 52))
                            .foregroundColor(.black)
                            .opacity(reviewState == .idle && animateIn ? 1 : 0)
                            .scaleEffect(reviewState == .idle && animateIn ? 1 : 0.8)
                        
                        // Crown loading animation (loading state)
                        CrownLoadingView(size: isCompact ? 48 : 56, tint: .black)
                            .opacity(reviewState == .loading ? 1 : 0)
                            .scaleEffect(reviewState == .loading ? crownScale : 0.6)
                        
                        // Checkmark (completed state)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: isCompact ? 48 : 56))
                            .foregroundColor(.black)
                            .opacity(reviewState == .completed ? 1 : 0)
                            .scaleEffect(reviewState == .completed ? 1 : 0.5)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: reviewState)
                    .animation(.easeOut(duration: 0.5), value: animateIn)
                    
                    // Main text - changes based on state
                    Group {
                        switch reviewState {
                        case .idle:
                            Text("Enjoying Scroll The Bible?")
                        case .loading:
                            Text("Opening App Store...")
                        case .completed:
                            Text("Thank you!")
                        }
                    }
                    .font(.custom("Georgia", size: isCompact ? 22 : 26))
                    .fontWeight(.regular)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .padding(.horizontal, isCompact ? 20 : 24)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 15)
                    .animation(.easeOut(duration: 0.4), value: animateIn)
                    .animation(.easeInOut(duration: 0.3), value: reviewState)
                    
                    // Subtitle - changes based on state
                    Group {
                        switch reviewState {
                        case .idle:
                            Text("Your review helps others discover God's Word.")
                        case .loading:
                            Text("Please leave your rating when prompted.")
                        case .completed:
                            Text("Your support means everything to us.")
                        }
                    }
                    .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                    .foregroundColor(.gray)
                    .tracking(0.5)
                    .multilineTextAlignment(.center)
                    .lineSpacing(isCompact ? 3 : 4)
                    .padding(.horizontal, isCompact ? 30 : 40)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)
                    .animation(.easeInOut(duration: 0.3), value: reviewState)
                    
                    // Button area
                    switch reviewState {
                    case .idle:
                        Button(action: {
                            triggerReviewFlow()
                        }) {
                            Text("Yes, I'll leave a review")
                                .font(.system(size: isCompact ? 14 : 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, isCompact ? 28 : 32)
                                .padding(.vertical, isCompact ? 14 : 16)
                                .background(
                                    Capsule()
                                        .fill(Color.black)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: animateIn)
                        
                    case .loading:
                        HStack(spacing: 10) {
                            CrownLoadingView(size: 18, tint: .white)
                        }
                        .padding(.horizontal, isCompact ? 36 : 44)
                        .padding(.vertical, isCompact ? 14 : 16)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.85))
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        
                    case .completed:
                        Color.clear
                            .frame(height: isCompact ? 46 : 54)
                            .transition(.opacity)
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            guard !Self.hasAnimated else { return }
            Self.hasAnimated = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateIn = true
            }
        }
        .onDisappear {
            animateIn = false
            Self.hasAnimated = false
        }
    }
    
    private func triggerReviewFlow() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Immediately mark that user has engaged - prevents future review prompts
        hasLeftReview = true
        
        // Transition to loading state
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            reviewState = .loading
            crownScale = 1.0
        }
        
        // Start crown pulse animation
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            crownScale = 1.08
        }
        
        // Wait for animation, then trigger Apple's review prompt
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            requestReview()
            
            // Transition to completed after giving time for review dialog
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                let success = UINotificationFeedbackGenerator()
                success.notificationOccurred(.success)
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    reviewState = .completed
                }
            }
        }
    }
}

// MARK: - Share Request Card View
struct ShareRequestCardView: View {
    // Static tracking to survive view recreation during app lifecycle
    private static var hasAnimated = false
    
    @State private var animateIn = false
    @State private var showingShareSheet = false
    @State private var shareState: ShareState = .idle
    
    enum ShareState {
        case idle
        case loading
        case completed
    }
    
    // App Store URL for sharing
    private let appStoreURL = "https://apps.apple.com/us/app/scroll-the-bible/id6756558351"
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700
            
            ZStack {
                Color.white
                
                VStack(spacing: isCompact ? 24 : 32) {
                    Spacer()
                    
                    // Share icon
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: isCompact ? 40 : 48, weight: .medium))
                        .foregroundColor(.black)
                        .opacity(animateIn ? 1 : 0)
                        .scaleEffect(animateIn ? 1 : 0.8)
                        .animation(.easeOut(duration: 0.5), value: animateIn)
                    
                    // Main text
                    Text("Share with a friend?")
                        .font(.custom("Georgia", size: isCompact ? 22 : 26))
                        .fontWeight(.regular)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .padding(.horizontal, isCompact ? 20 : 24)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 15)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)
                    
                    // Subtitle
                    Text("Help others discover God's Word.")
                        .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .multilineTextAlignment(.center)
                        .lineSpacing(isCompact ? 3 : 4)
                        .padding(.horizontal, isCompact ? 30 : 40)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.15), value: animateIn)
                    
                    // Share button / Loading / Thank you
                    if shareState == .completed {
                        Text("Thank you!")
                            .font(.system(size: isCompact ? 14 : 16, weight: .medium))
                            .foregroundColor(.black)
                            .transition(.opacity)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 10)
                            .animation(.easeOut(duration: 0.4).delay(0.2), value: animateIn)
                    } else {
                        Button(action: {
                            guard shareState == .idle else { return }
                            
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            
                            withAnimation(.easeInOut(duration: 0.2)) {
                                shareState = .loading
                            }
                            
                            showingShareSheet = true
                        }) {
                            HStack(spacing: 10) {
                                if shareState == .loading {
                                    CrownLoadingView(size: 16, tint: .white)
                                }
                                Text(shareState == .loading ? "Loading..." : "Share the app")
                                    .font(.system(size: isCompact ? 14 : 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, isCompact ? 28 : 32)
                            .padding(.vertical, isCompact ? 14 : 16)
                            .background(
                                Capsule()
                                    .fill(shareState == .loading ? Color.gray : Color.black)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(shareState == .loading)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: animateIn)
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            guard !Self.hasAnimated else { return }
            Self.hasAnimated = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateIn = true
            }
        }
        .onDisappear {
            animateIn = false
            Self.hasAnimated = false
        }
        .sheet(isPresented: $showingShareSheet, onDismiss: {
            // Transition to thank you when share sheet is dismissed
            withAnimation(.easeInOut(duration: 0.3)) {
                shareState = .completed
            }
        }) {
            ShareSheet(items: [URL(string: appStoreURL)!])
        }
    }
}

// MARK: - Share Sheet (UIKit wrapper)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Tutorial Button Demo View
struct TutorialButtonDemoView: View {
    let demo: TutorialButtonDemo
    var isCompact: Bool = false
    
    var body: some View {
        switch demo {
        case .like:
            LikeButtonDemo(isCompact: isCompact)
        case .notes:
            NotesButtonDemo(isCompact: isCompact)
        case .share:
            ShareButtonDemo(isCompact: isCompact)
        case .crown:
            CrownButtonDemo(isCompact: isCompact)
        case .bookPicker:
            BookPickerDemo(isCompact: isCompact)
        case .favorites:
            FavoritesDemo(isCompact: isCompact)
        case .translation:
            TranslationDemo(isCompact: isCompact)
        case .notesHeader:
            NotesHeaderDemo(isCompact: isCompact)
        case .search:
            SearchDemo(isCompact: isCompact)
        }
    }
}

// MARK: - Button Demos
struct LikeButtonDemo: View {
    var isCompact: Bool = false
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
                    .frame(width: isCompact ? 22 : 28, height: isCompact ? 22 : 28)
                    .foregroundColor(isLiked ? .red : .black)
                    .padding(isCompact ? 14 : 18)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: isCompact ? 12 : 16, x: 0, y: isCompact ? 4 : 6)
                    )
                    .scaleEffect(isLiked ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isLiked)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotesButtonDemo: View {
    var isCompact: Bool = false
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
                .frame(width: isCompact ? 22 : 28, height: isCompact ? 22 : 28)
                .foregroundColor(.black)
                .padding(isCompact ? 14 : 18)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: isCompact ? 12 : 16, x: 0, y: isCompact ? 4 : 6)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShareButtonDemo: View {
    var isCompact: Bool = false
    
    var body: some View {
        Image("bx-send")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: isCompact ? 22 : 28, height: isCompact ? 22 : 28)
            .foregroundColor(.black)
            .padding(isCompact ? 14 : 18)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: isCompact ? 12 : 16, x: 0, y: isCompact ? 4 : 6)
            )
    }
}

struct CrownButtonDemo: View {
    var isCompact: Bool = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Image("crown-icon")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: isCompact ? 45 : 60, height: isCompact ? 45 : 60)
            .foregroundColor(.black)
            .padding(isCompact ? 12 : 16)
            .background(
                RoundedRectangle(cornerRadius: isCompact ? 16 : 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: isCompact ? 12 : 16, x: 0, y: isCompact ? 4 : 6)
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
    var isCompact: Bool = false
    
    var body: some View {
        HStack(spacing: isCompact ? 3 : 4) {
            Text("Genesis")
                .font(.system(size: isCompact ? 12 : 14, weight: .medium))
            Text("1")
                .font(.system(size: isCompact ? 11 : 13, weight: .regular))
                .foregroundColor(.gray)
            Image(systemName: "chevron.down")
                .font(.system(size: isCompact ? 8 : 10, weight: .semibold))
                .foregroundColor(.gray)
        }
        .foregroundColor(.black)
        .padding(.horizontal, isCompact ? 10 : 14)
        .padding(.vertical, isCompact ? 8 : 10)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: isCompact ? 8 : 12, x: 0, y: isCompact ? 3 : 4)
        )
    }
}

struct FavoritesDemo: View {
    var isCompact: Bool = false
    
    var body: some View {
        HStack(spacing: isCompact ? 8 : 12) {
            // Notes button
            Image("bxs-message")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isCompact ? 16 : 20, height: isCompact ? 16 : 20)
                .foregroundColor(.black)
                .padding(isCompact ? 10 : 12)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: isCompact ? 8 : 10, x: 0, y: isCompact ? 3 : 4)
                )
            
            // Favorites button
            Image("bxs-heart")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isCompact ? 16 : 20, height: isCompact ? 16 : 20)
                .foregroundColor(.black)
                .padding(isCompact ? 10 : 12)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: isCompact ? 8 : 10, x: 0, y: isCompact ? 3 : 4)
                )
        }
    }
}

struct TranslationDemo: View {
    var isCompact: Bool = false
    
    var body: some View {
        Text("KJV")
            .font(.system(size: isCompact ? 10 : 12, weight: .semibold))
            .foregroundColor(.black)
            .padding(isCompact ? 10 : 12)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: isCompact ? 8 : 10, x: 0, y: isCompact ? 3 : 4)
            )
    }
}

struct NotesHeaderDemo: View {
    var isCompact: Bool = false
    
    var body: some View {
        Image("bxs-message")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: isCompact ? 16 : 20, height: isCompact ? 16 : 20)
            .foregroundColor(.black)
            .padding(isCompact ? 10 : 12)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: isCompact ? 8 : 10, x: 0, y: isCompact ? 3 : 4)
            )
    }
}

struct SearchDemo: View {
    var isCompact: Bool = false
    
    var body: some View {
        Image(systemName: "magnifyingglass")
            .font(.system(size: isCompact ? 13 : 16, weight: .medium))
            .foregroundColor(.black)
            .padding(isCompact ? 10 : 12)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: isCompact ? 8 : 10, x: 0, y: isCompact ? 3 : 4)
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

// MARK: - Last Card Scroll Hint
struct LastCardScrollHint: View {
    @State private var animating = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chevron.up")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.gray.opacity(0.6))
                .offset(y: animating ? -8 : 0)
            
            Text("Swipe up to begin")
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

// MARK: - Tutorial Exit Trigger
struct TutorialExitTrigger: View {
    let onTrigger: () -> Void
    @State private var hasTriggered = false
    
    var body: some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .global)
            // Page is "settled" when its top is near the top of the screen (within safe area)
            let isSettled = frame.minY >= -10 && frame.minY <= 100
            
            Color.white
                .onChange(of: isSettled) { oldValue, newValue in
                    // Only trigger when transitioning from not settled to settled
                    if newValue && !oldValue && !hasTriggered {
                        hasTriggered = true
                        // Wait 0.5 second on the blank white screen, then trigger
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onTrigger()
                        }
                    }
                }
                .onAppear {
                    // Also check on appear in case it's already settled
                    if isSettled && !hasTriggered {
                        hasTriggered = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onTrigger()
                        }
                    }
                }
        }
    }
}

// MARK: - Paywall View
struct PaywallView: View {
    var onComplete: (() -> Void)? = nil
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    // State passed from parent to persist across re-renders
    @Binding var selectedPlan: SubscriptionPlan
    @Binding var withFreeTrial: Bool
    @Binding var isPurchasing: Bool
    
    enum SubscriptionPlan {
        case monthly
        case yearly
    }
    
    // Convenience init for preview/standalone use
    init(
        onComplete: (() -> Void)? = nil,
        selectedPlan: Binding<SubscriptionPlan> = .constant(.yearly),
        withFreeTrial: Binding<Bool> = .constant(false),
        isPurchasing: Binding<Bool> = .constant(false)
    ) {
        self.onComplete = onComplete
        self._selectedPlan = selectedPlan
        self._withFreeTrial = withFreeTrial
        self._isPurchasing = isPurchasing
    }
    
    var body: some View {
        // iOS 26+: Use GeometryReader with ScrollView (works perfectly)
        // iOS 18 and below: Use simpler structure without nested GeometryReader
        if #available(iOS 26, *) {
            GeometryReader { geometry in
                let isCompact = geometry.size.height < 700
                let isVeryCompact = geometry.size.height < 650
                let horizontalPadding: CGFloat = min(32, geometry.size.width * 0.08)
                
                ZStack {
                    Color.white
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        paywallContent(geometry: geometry, isCompact: isCompact, isVeryCompact: isVeryCompact, horizontalPadding: horizontalPadding)
                            .frame(minHeight: geometry.size.height)
                    }
                    .scrollDisabled(geometry.size.height >= 750)
                }
            }
        } else {
            // iOS 18 and below: Simple structure that fills parent
            iOS18PaywallContent(
                onComplete: onComplete,
                selectedPlan: $selectedPlan,
                withFreeTrial: $withFreeTrial,
                isPurchasing: $isPurchasing,
                subscriptionService: subscriptionService
            )
        }
    }
    
    // MARK: - Paywall Content (shared between iOS versions)
    @ViewBuilder
    private func paywallContent(geometry: GeometryProxy, isCompact: Bool, isVeryCompact: Bool, horizontalPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: isVeryCompact ? 20 : (isCompact ? 30 : 50))
            
            // Crown icon
            Image("crown-icon")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isVeryCompact ? 50 : (isCompact ? 55 : 65), height: isVeryCompact ? 50 : (isCompact ? 55 : 65))
                .foregroundColor(.black)
            
            Spacer()
                .frame(height: isVeryCompact ? 14 : (isCompact ? 16 : 24))
            
            // Title
            Text("Unlock Scroll The Bible")
                .font(.custom("Georgia", size: isVeryCompact ? 22 : (isCompact ? 24 : 28)))
                .fontWeight(.regular)
                .foregroundColor(.black)
            
            Spacer()
                .frame(height: isVeryCompact ? 6 : (isCompact ? 8 : 10))
            
            // Subtitle
            Text("Deeper study. Unlimited access.")
                .font(.system(size: isVeryCompact ? 12 : (isCompact ? 13 : 15), weight: .medium))
                .foregroundColor(.gray)
                .tracking(0.5)
            
            Spacer()
                .frame(height: isVeryCompact ? 18 : (isCompact ? 24 : 32))
            
            // Features list
            VStack(spacing: isVeryCompact ? 10 : (isCompact ? 12 : 14)) {
                FeatureRow(text: "AI-powered Bible study", isCompact: isCompact)
                FeatureRow(text: "Explain It Easier button", isCompact: isCompact)
                FeatureRow(text: "Cross-references & context", isCompact: isCompact)
                FeatureRow(text: "Ad-free experience", isCompact: isCompact)
            }
            
            Spacer()
                .frame(height: isVeryCompact ? 16 : (isCompact ? 20 : 28))
            
            // Free trial toggle
            FreeTrialToggle(withFreeTrial: $withFreeTrial, isCompact: isCompact)
                .padding(.horizontal, horizontalPadding)
            
            Spacer()
                .frame(height: isVeryCompact ? 12 : (isCompact ? 14 : 18))
            
            // Subscription options
            VStack(spacing: isVeryCompact ? 8 : (isCompact ? 10 : 12)) {
                // Yearly plan
                SubscriptionOptionView(
                    plan: .yearly,
                    isSelected: selectedPlan == .yearly,
                    withFreeTrial: withFreeTrial,
                    isCompact: isCompact,
                    onSelect: { selectedPlan = .yearly },
                    getPrice: getPrice,
                    getSavings: getSavings
                )
                
                // Monthly plan
                SubscriptionOptionView(
                    plan: .monthly,
                    isSelected: selectedPlan == .monthly,
                    withFreeTrial: withFreeTrial,
                    isCompact: isCompact,
                    onSelect: { selectedPlan = .monthly },
                    getPrice: getPrice,
                    getSavings: getSavings
                )
                
                // No commitment text
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: isVeryCompact ? 9 : (isCompact ? 10 : 12), weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("No commitment · Cancel anytime")
                        .font(.system(size: isVeryCompact ? 9 : (isCompact ? 10 : 12), weight: .regular))
                        .foregroundColor(.gray)
                }
                .padding(.top, isVeryCompact ? 2 : (isCompact ? 2 : 4))
            }
            .padding(.horizontal, horizontalPadding)
            
            Spacer()
                .frame(height: isVeryCompact ? 10 : (isCompact ? 12 : 14))
            
            // Subscribe button
            Button(action: {
                Task {
                    await purchaseSubscription()
                }
            }) {
                HStack(spacing: 8) {
                    if isPurchasing {
                        CrownLoadingView(size: 18, tint: .white)
                    }
                    Text(isPurchasing ? "Processing..." : "Continue")
                        .font(.system(size: isVeryCompact ? 14 : (isCompact ? 15 : 17), weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, isVeryCompact ? 12 : (isCompact ? 14 : 16))
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isPurchasing ? Color.gray : Color.black)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, horizontalPadding)
            .disabled(isPurchasing)
            
            Spacer()
                .frame(height: isVeryCompact ? 8 : (isCompact ? 10 : 12))
            
            // Restore purchases
            Button(action: {
                Task {
                    await subscriptionService.restorePurchases()
                    if subscriptionService.isPremium {
                        onComplete?()
                    }
                }
            }) {
                Text("Restore Purchases")
                    .font(.system(size: isVeryCompact ? 10 : (isCompact ? 11 : 13), weight: .medium))
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
                .frame(height: isVeryCompact ? 4 : (isCompact ? 6 : 8))
            
            // Terms and Privacy Links (Required by App Store)
            HStack(spacing: 4) {
                Link("Terms", destination: URL(string: APIConfig.termsOfUseURL)!)
                Text("·")
                Link("Privacy", destination: URL(string: APIConfig.privacyPolicyURL)!)
            }
            .font(.system(size: isVeryCompact ? 8 : (isCompact ? 9 : 10), weight: .regular))
            .tint(.gray.opacity(0.5))
            .foregroundStyle(.gray.opacity(0.5))
            .padding(.bottom, isVeryCompact ? 12 : (isCompact ? 16 : 20))
        }
    }
    
    // MARK: - Helper Methods
    
    private func purchaseSubscription() async {
        // Capture current selections before any async work
        let currentPlan = selectedPlan
        let currentTrial = withFreeTrial
        
        isPurchasing = true
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        guard let product = subscriptionService.getProduct(
            yearly: currentPlan == .yearly,
            withTrial: currentTrial
        ) else {
            print("❌ Product not found")
            isPurchasing = false
            return
        }
        
        let success = await subscriptionService.purchase(product)
        
        isPurchasing = false
        if success {
            // Complete tutorial on successful purchase
            onComplete?()
        }
    }
    
    private func getPrice(for plan: SubscriptionPlan, withTrial: Bool) -> String {
        if let product = subscriptionService.getProduct(yearly: plan == .yearly, withTrial: withTrial) {
            return product.displayPrice
        }
        // Fallback to hardcoded prices
        switch (plan, withTrial) {
        case (.monthly, false): return "$3.99"
        case (.monthly, true): return "$4.99"
        case (.yearly, false): return "$19.99"
        case (.yearly, true): return "$29.99"
        }
    }
    
    private func getSavings(for plan: SubscriptionPlan, withTrial: Bool) -> String? {
        switch plan {
        case .monthly: return nil
        case .yearly: return withTrial ? "Save 50%" : "Save 58%"
        }
    }
}

// MARK: - iOS 18 Paywall Content (Simplified structure without GeometryReader issues)
struct iOS18PaywallContent: View {
    var onComplete: (() -> Void)?
    @Binding var selectedPlan: PaywallView.SubscriptionPlan
    @Binding var withFreeTrial: Bool
    @Binding var isPurchasing: Bool
    var subscriptionService: SubscriptionService
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700
            let isVeryCompact = geometry.size.height < 650
            let horizontalPadding: CGFloat = min(32, geometry.size.width * 0.08)
            
            Color.white
                .ignoresSafeArea()
                .overlay(
                    VStack(spacing: 0) {
                        // Top spacing for iOS 18
                        Spacer()
                            .frame(height: isVeryCompact ? 100 : (isCompact ? 120 : 140))
                        
                        // Crown icon
                        Image("crown-icon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isVeryCompact ? 45 : (isCompact ? 50 : 60), height: isVeryCompact ? 45 : (isCompact ? 50 : 60))
                            .foregroundColor(.black)
                        
                        Spacer().frame(height: isVeryCompact ? 12 : (isCompact ? 14 : 20))
                        
                        // Title
                        Text("Unlock Scroll The Bible")
                            .font(.custom("Georgia", size: isVeryCompact ? 20 : (isCompact ? 22 : 26)))
                            .fontWeight(.regular)
                            .foregroundColor(.black)
                        
                        Spacer().frame(height: isVeryCompact ? 4 : (isCompact ? 6 : 8))
                        
                        // Subtitle
                        Text("Deeper study. Unlimited access.")
                            .font(.system(size: isVeryCompact ? 11 : (isCompact ? 12 : 14), weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(0.5)
                        
                        Spacer().frame(height: isVeryCompact ? 14 : (isCompact ? 18 : 24))
                        
                        // Features list
                        VStack(spacing: isVeryCompact ? 8 : (isCompact ? 10 : 12)) {
                            iOS18FeatureRow(text: "AI-powered Bible study", isCompact: isCompact, isVeryCompact: isVeryCompact)
                            iOS18FeatureRow(text: "Explain It Easier button", isCompact: isCompact, isVeryCompact: isVeryCompact)
                            iOS18FeatureRow(text: "Cross-references & context", isCompact: isCompact, isVeryCompact: isVeryCompact)
                            iOS18FeatureRow(text: "Ad-free experience", isCompact: isCompact, isVeryCompact: isVeryCompact)
                        }
                        
                        Spacer().frame(height: isVeryCompact ? 14 : (isCompact ? 18 : 24))
                        
                        // Free trial toggle
                        FreeTrialToggle(withFreeTrial: $withFreeTrial, isCompact: isCompact)
                            .padding(.horizontal, horizontalPadding)
                        
                        Spacer().frame(height: isVeryCompact ? 10 : (isCompact ? 12 : 16))
                        
                        // Subscription options
                        VStack(spacing: isVeryCompact ? 8 : (isCompact ? 10 : 12)) {
                            SubscriptionOptionView(
                                plan: .yearly,
                                isSelected: selectedPlan == .yearly,
                                withFreeTrial: withFreeTrial,
                                isCompact: isCompact,
                                onSelect: { selectedPlan = .yearly },
                                getPrice: getPrice,
                                getSavings: getSavings
                            )
                            
                            SubscriptionOptionView(
                                plan: .monthly,
                                isSelected: selectedPlan == .monthly,
                                withFreeTrial: withFreeTrial,
                                isCompact: isCompact,
                                onSelect: { selectedPlan = .monthly },
                                getPrice: getPrice,
                                getSavings: getSavings
                            )
                            
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: isVeryCompact ? 9 : (isCompact ? 10 : 11), weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Text("No commitment · Cancel anytime")
                                    .font(.system(size: isVeryCompact ? 9 : (isCompact ? 10 : 11), weight: .regular))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 2)
                        }
                        .padding(.horizontal, horizontalPadding)
                        
                        Spacer().frame(height: isVeryCompact ? 10 : (isCompact ? 12 : 14))
                        
                        // Subscribe button
                        Button(action: {
                            Task {
                                await purchaseSubscription()
                            }
                        }) {
                            HStack(spacing: 8) {
                                if isPurchasing {
                                    CrownLoadingView(size: 16, tint: .white)
                                }
                                Text(isPurchasing ? "Processing..." : "Continue")
                                    .font(.system(size: isVeryCompact ? 14 : (isCompact ? 15 : 16), weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, isVeryCompact ? 12 : (isCompact ? 13 : 14))
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isPurchasing ? Color.gray : Color.black)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, horizontalPadding)
                        .disabled(isPurchasing)
                        
                        Spacer().frame(height: isVeryCompact ? 8 : (isCompact ? 10 : 12))
                        
                        // Restore purchases
                        Button(action: {
                            Task {
                                await subscriptionService.restorePurchases()
                                if subscriptionService.isPremium {
                                    onComplete?()
                                }
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(.system(size: isVeryCompact ? 10 : (isCompact ? 11 : 12), weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer().frame(height: isVeryCompact ? 4 : (isCompact ? 6 : 8))
                        
                        // Terms and Privacy
                        HStack(spacing: 4) {
                            Link("Terms", destination: URL(string: APIConfig.termsOfUseURL)!)
                            Text("·")
                            Link("Privacy", destination: URL(string: APIConfig.privacyPolicyURL)!)
                        }
                        .font(.system(size: isVeryCompact ? 8 : (isCompact ? 9 : 10), weight: .regular))
                        .tint(.gray.opacity(0.5))
                        .foregroundStyle(.gray.opacity(0.5))
                        
                        Spacer()
                    }
                )
        }
    }
    
    private func purchaseSubscription() async {
        let currentPlan = selectedPlan
        let currentTrial = withFreeTrial
        
        isPurchasing = true
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        guard let product = subscriptionService.getProduct(
            yearly: currentPlan == .yearly,
            withTrial: currentTrial
        ) else {
            isPurchasing = false
            return
        }
        
        let success = await subscriptionService.purchase(product)
        
        isPurchasing = false
        if success {
            onComplete?()
        }
    }
    
    private func getPrice(for plan: PaywallView.SubscriptionPlan, withTrial: Bool) -> String {
        if let product = subscriptionService.getProduct(yearly: plan == .yearly, withTrial: withTrial) {
            return product.displayPrice
        }
        switch (plan, withTrial) {
        case (.monthly, false): return "$3.99"
        case (.monthly, true): return "$4.99"
        case (.yearly, false): return "$19.99"
        case (.yearly, true): return "$29.99"
        }
    }
    
    private func getSavings(for plan: PaywallView.SubscriptionPlan, withTrial: Bool) -> String? {
        switch plan {
        case .monthly: return nil
        case .yearly: return withTrial ? "Save 50%" : "Save 58%"
        }
    }
}

// MARK: - iOS 18 Feature Row
struct iOS18FeatureRow: View {
    let text: String
    var isCompact: Bool = false
    var isVeryCompact: Bool = false
    
    var body: some View {
        HStack(spacing: isVeryCompact ? 8 : (isCompact ? 10 : 12)) {
            Image(systemName: "checkmark")
                .font(.system(size: isVeryCompact ? 9 : (isCompact ? 10 : 11), weight: .bold))
                .foregroundColor(.black)
            
            Text(text)
                .font(.system(size: isVeryCompact ? 12 : (isCompact ? 13 : 14), weight: .regular))
                .foregroundColor(.black.opacity(0.8))
            
            Spacer()
        }
        .padding(.horizontal, isVeryCompact ? 36 : (isCompact ? 40 : 46))
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let text: String
    var isCompact: Bool = false
    
    var body: some View {
        HStack(spacing: isCompact ? 10 : 12) {
            Image(systemName: "checkmark")
                .font(.system(size: isCompact ? 10 : 12, weight: .bold))
                .foregroundColor(.black)
            
            Text(text)
                .font(.system(size: isCompact ? 13 : 15, weight: .regular))
                .foregroundColor(.black.opacity(0.8))
            
            Spacer()
        }
        .padding(.horizontal, isCompact ? 40 : 50)
    }
}

// MARK: - Free Trial Toggle
struct FreeTrialToggle: View {
    @Binding var withFreeTrial: Bool
    var isCompact: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Pay Now option (left)
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.2)) {
                    withFreeTrial = false 
                }
            }) {
                Text("Pay Now")
                    .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                    .foregroundColor(withFreeTrial ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompact ? 10 : 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(withFreeTrial ? Color.clear : Color.black)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Free Trial option (right)
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.2)) {
                    withFreeTrial = true 
                }
            }) {
                Text("Free Trial")
                    .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                    .foregroundColor(withFreeTrial ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompact ? 10 : 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(withFreeTrial ? Color.black : Color.clear)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Subscription Option View
struct SubscriptionOptionView: View {
    let plan: PaywallView.SubscriptionPlan
    let isSelected: Bool
    let withFreeTrial: Bool
    var isCompact: Bool = false
    let onSelect: () -> Void
    let getPrice: (PaywallView.SubscriptionPlan, Bool) -> String
    let getSavings: (PaywallView.SubscriptionPlan, Bool) -> String?
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.black : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: isCompact ? 18 : 22, height: isCompact ? 18 : 22)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.black)
                            .frame(width: isCompact ? 10 : 12, height: isCompact ? 10 : 12)
                    }
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(plan == .yearly ? "Annual" : "Monthly")
                            .font(.system(size: isCompact ? 14 : 16, weight: .medium))
                            .foregroundColor(.black)
                        
                        if let savings = getSavings(plan, withFreeTrial) {
                            Text(savings)
                                .font(.system(size: isCompact ? 9 : 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, isCompact ? 6 : 8)
                                .padding(.vertical, isCompact ? 2 : 3)
                                .background(
                                    Capsule()
                                        .fill(Color.black)
                                )
                        }
                    }
                    
                    // Billing frequency for App Store compliance
                    Text(plan == .yearly ? "Billed annually" : "Billed monthly")
                        .font(.system(size: isCompact ? 9 : 10, weight: .regular))
                        .foregroundColor(.gray.opacity(0.6))
                }
                
                Spacer()
                
                // Price
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(plan == .yearly ? (withFreeTrial ? "$2.49" : "$1.67") : getPrice(plan, withFreeTrial))
                        .font(.system(size: isCompact ? 16 : 18, weight: .semibold))
                        .foregroundColor(.black)
                    Text("/month")
                        .font(.system(size: isCompact ? 10 : 12, weight: .regular))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, isCompact ? 14 : 18)
            .padding(.vertical, isCompact ? 12 : 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.black : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.black.opacity(0.03) : Color.clear)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TutorialView(isShowingTutorial: .constant(true))
}

#Preview("Paywall") {
    PaywallView()
}
