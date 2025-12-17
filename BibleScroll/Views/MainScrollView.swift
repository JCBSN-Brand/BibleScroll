//
//  MainScrollView.swift
//  BibleScroll
//
//  TikTok-style vertical paging scroll view for Bible verses
//

import SwiftUI
import SwiftData
import StoreKit

struct MainScrollView: View {
    @ObservedObject var viewModel: BibleViewModel
    @ObservedObject var authService: AuthService
    @Environment(\.modelContext) private var modelContext
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @State private var scrollPosition: Int?
    @State private var isLoadingNextChapter: Bool = false
    @State private var contentOpacity: Double = 1.0
    
    // Review prompt tracking
    @AppStorage("hasLeftReview") private var hasLeftReview = false
    
    // Grace period tracking - no ads for first 20 verses after tutorial
    @AppStorage("totalVersesViewed") private var totalVersesViewed = 0
    private let gracePeriodVerses = 20
    
    // Show review card at these verse intervals (every ~25-30 verses, avoiding paywall multiples of 20)
    private let reviewIntervals: Set<Int> = [8, 35, 65, 95, 125]
    
    // Show share card more rarely (every ~30-40 verses, always shows)
    private let shareIntervals: Set<Int> = [12, 52, 92, 132]
    
    var body: some View {
        GeometryReader { geometry in
            if viewModel.isLoading {
                // Loading state
                VStack {
                    Spacer()
                    CrownLoadingView(size: 32, tint: .black)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.verses.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No verses found")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Vertical scrolling with snapping
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.verses.enumerated()), id: \.element.id) { index, verse in
                            VerseCardView(
                                verse: verse,
                                favoritesViewModel: favoritesViewModel,
                                authService: authService
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .opacity(contentOpacity)
                            .id(index)
                            
                            // Only show promotional cards after grace period (first 20 verses)
                            if totalVersesViewed >= gracePeriodVerses {
                                // Show review card at specific intervals if user hasn't left a review yet
                                if !hasLeftReview && reviewIntervals.contains(index + 1) && index < viewModel.verses.count - 1 {
                                    ReviewCardView(hasLeftReview: $hasLeftReview)
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .id("review-\(index)")
                                }
                                
                                // Show share card at specific intervals (always shows, more rare)
                                if shareIntervals.contains(index + 1) && index < viewModel.verses.count - 1 {
                                    ShareCardView()
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .id("share-\(index)")
                                }
                                
                                // Show paywall every 20 verses for non-premium users
                                if !authService.isPremium && (index + 1) % 20 == 0 && index < viewModel.verses.count - 1 {
                                    PaywallCardView()
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .id("paywall-\(index)")
                                }
                            }
                        }
                        
                        // Next chapter trigger - appears after the last verse
                        NextChapterTriggerView(
                            currentBook: viewModel.currentBook,
                            currentChapter: viewModel.currentChapter,
                            books: viewModel.books,
                            isLoading: $isLoadingNextChapter,
                            onTrigger: {
                                guard !isLoadingNextChapter else { return }
                                isLoadingNextChapter = true
                                
                                Task {
                                    await viewModel.nextChapter()
                                    // Reset scroll position to first verse of new chapter
                                    scrollPosition = 0
                                    
                                    // Start with content hidden, then fade in
                                    contentOpacity = 0
                                    withAnimation(.easeIn(duration: 0.4)) {
                                        contentOpacity = 1.0
                                    }
                                    
                                    isLoadingNextChapter = false
                                }
                            }
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .id(viewModel.verses.count) // ID after all verses
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $scrollPosition)
                .scrollTargetBehavior(.paging)
                .onChange(of: scrollPosition) { oldPosition, newPosition in
                    if let newPosition = newPosition, newPosition < viewModel.verses.count {
                        viewModel.updateCurrentVerse(to: newPosition)
                        
                        // Track total verses viewed for grace period (only count forward scrolls)
                        if oldPosition == nil || (oldPosition != nil && newPosition > oldPosition!) {
                            if totalVersesViewed < gracePeriodVerses + 10 { // Cap tracking after grace period
                                totalVersesViewed += 1
                            }
                        }
                    }
                }
                .onAppear {
                    // Scroll to saved verse position when view appears
                    scrollPosition = viewModel.currentVerseIndex
                }
            }
        }
        .background(Color.white)
        .ignoresSafeArea()
        .onAppear {
            favoritesViewModel.setup(with: modelContext)
        }
    }
}

// MARK: - Paywall Card View
struct PaywallCardView: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var withFreeTrial: Bool = false
    @State private var animateIn = false
    @State private var isPurchasing = false
    
    enum PaywallPlan {
        case monthly
        case yearly
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700
            let isVeryCompact = geometry.size.height < 650
            let horizontalPadding: CGFloat = min(28, geometry.size.width * 0.07)
            
            ZStack {
                Color.white
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(minHeight: 120)  // Ensure minimum top spacing to avoid header
                    
                    VStack(spacing: 0) {
                        // Crown icon
                        Image("crown-icon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isVeryCompact ? 50 : (isCompact ? 55 : 65), height: isVeryCompact ? 50 : (isCompact ? 55 : 65))
                            .foregroundColor(.black)
                            .opacity(animateIn ? 1 : 0)
                            .scaleEffect(animateIn ? 1 : 0.8)
                            .animation(.easeOut(duration: 0.5), value: animateIn)
                        
                        Spacer()
                            .frame(height: isVeryCompact ? 16 : (isCompact ? 18 : 22))
                        
                        // Title
                        Text("Unlock Scroll the Bible")
                            .font(.custom("Georgia", size: isVeryCompact ? 24 : (isCompact ? 26 : 28)))
                            .fontWeight(.regular)
                            .foregroundColor(.black)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 15)
                            .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)
                        
                        Spacer()
                            .frame(height: isVeryCompact ? 8 : (isCompact ? 10 : 12))
                        
                        // Subtitle
                        Text("Deeper study. Unlimited access.")
                            .font(.system(size: isVeryCompact ? 13 : (isCompact ? 14 : 15), weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(0.5)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 10)
                            .animation(.easeOut(duration: 0.4).delay(0.15), value: animateIn)
                        
                        Spacer()
                            .frame(height: isVeryCompact ? 20 : (isCompact ? 24 : 28))
                        
                        // Features list
                        VStack(spacing: isVeryCompact ? 10 : (isCompact ? 12 : 14)) {
                            PaywallCardFeatureRow(text: "AI-powered Bible study", isCompact: isCompact, isVeryCompact: isVeryCompact)
                            PaywallCardFeatureRow(text: "Explain It Easier button", isCompact: isCompact, isVeryCompact: isVeryCompact)
                            PaywallCardFeatureRow(text: "Cross-references & context", isCompact: isCompact, isVeryCompact: isVeryCompact)
                            PaywallCardFeatureRow(text: "Ad-free experience", isCompact: isCompact, isVeryCompact: isVeryCompact)
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 15)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: animateIn)
                        
                        Spacer()
                            .frame(height: isVeryCompact ? 18 : (isCompact ? 20 : 24))
                        
                        // Free trial toggle
                        PaywallCardFreeTrialToggle(withFreeTrial: $withFreeTrial, isCompact: isCompact, isVeryCompact: isVeryCompact)
                            .padding(.horizontal, horizontalPadding)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 15)
                            .animation(.easeOut(duration: 0.4).delay(0.22), value: animateIn)
                        
                        Spacer()
                            .frame(height: isVeryCompact ? 14 : (isCompact ? 16 : 18))
                        
                        // Subscription options
                        VStack(spacing: isVeryCompact ? 10 : (isCompact ? 11 : 12)) {
                            // Yearly plan
                            PaywallCardSubscriptionOption(
                                plan: .yearly,
                                isSelected: selectedPlan == .yearly,
                                withFreeTrial: withFreeTrial,
                                isCompact: isCompact,
                                isVeryCompact: isVeryCompact,
                                onSelect: { selectedPlan = .yearly },
                                getPrice: getPrice,
                                getSavings: getSavings
                            )
                            
                            // Monthly plan
                            PaywallCardSubscriptionOption(
                                plan: .monthly,
                                isSelected: selectedPlan == .monthly,
                                withFreeTrial: withFreeTrial,
                                isCompact: isCompact,
                                isVeryCompact: isVeryCompact,
                                onSelect: { selectedPlan = .monthly },
                                getPrice: getPrice,
                                getSavings: getSavings
                            )
                            
                            // No commitment text
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: isVeryCompact ? 10 : (isCompact ? 11 : 12), weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Text("No commitment · Cancel anytime")
                                    .font(.system(size: isVeryCompact ? 10 : (isCompact ? 11 : 12), weight: .regular))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, horizontalPadding)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 15)
                        .animation(.easeOut(duration: 0.4).delay(0.25), value: animateIn)
                        
                        Spacer()
                            .frame(height: isVeryCompact ? 14 : (isCompact ? 16 : 18))
                        
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
                                    .font(.system(size: isVeryCompact ? 15 : (isCompact ? 16 : 17), weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, isVeryCompact ? 13 : (isCompact ? 14 : 15))
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isPurchasing ? Color.gray : Color.black)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, horizontalPadding)
                        .disabled(isPurchasing)
                        .opacity(animateIn ? 1 : 0)
                        .scaleEffect(animateIn ? 1 : 0.95)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: animateIn)
                        
                        Spacer()
                            .frame(height: isVeryCompact ? 10 : (isCompact ? 12 : 14))
                        
                        // Restore purchases
                        Button(action: {
                            Task {
                                await subscriptionService.restorePurchases()
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(.system(size: isVeryCompact ? 11 : (isCompact ? 12 : 13), weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.35), value: animateIn)
                        
                        Spacer()
                            .frame(height: isVeryCompact ? 12 : (isCompact ? 14 : 18))
                        
                        // Terms
                        HStack(spacing: 4) {
                            Text("Terms")
                                .underline()
                            Text("·")
                            Text("Privacy")
                                .underline()
                        }
                        .font(.system(size: isVeryCompact ? 10 : (isCompact ? 11 : 12), weight: .regular))
                        .foregroundColor(.gray.opacity(0.7))
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.4), value: animateIn)
                    }
                    
                    Spacer()
                        .frame(minHeight: 20)  // Ensure minimum bottom spacing
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func purchaseSubscription() async {
        isPurchasing = true
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        guard let product = subscriptionService.getProduct(
            yearly: selectedPlan == .yearly,
            withTrial: withFreeTrial
        ) else {
            print("❌ Product not found")
            isPurchasing = false
            return
        }
        
        await subscriptionService.purchase(product)
        isPurchasing = false
    }
    
    private func getPrice(for plan: PaywallPlan, withTrial: Bool) -> String {
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
    
    private func getSavings(for plan: PaywallPlan, withTrial: Bool) -> String? {
        switch plan {
        case .monthly: return nil
        case .yearly: return withTrial ? "Save 50%" : "Save 58%"
        }
    }
}

// MARK: - Review Card View (for main scroll)
struct ReviewCardView: View {
    @Environment(\.requestReview) private var requestReview
    @Binding var hasLeftReview: Bool
    @State private var animateIn = false
    @State private var reviewState: ReviewState = .idle
    
    enum ReviewState {
        case idle
        case loading
        case completed
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700
            let isVeryCompact = geometry.size.height < 650
            
            ZStack {
                Color.white
                
                VStack(spacing: isVeryCompact ? 20 : (isCompact ? 26 : 32)) {
                    Spacer()
                    
                    // Star icon
                    Image(systemName: "star.fill")
                        .font(.system(size: isVeryCompact ? 40 : (isCompact ? 48 : 56)))
                        .foregroundColor(.black)
                        .opacity(animateIn ? 1 : 0)
                        .scaleEffect(animateIn ? 1 : 0.8)
                        .animation(.easeOut(duration: 0.5), value: animateIn)
                    
                    // Main text
                    Text("Enjoying Scroll The Bible?")
                        .font(.custom("Georgia", size: isVeryCompact ? 22 : (isCompact ? 24 : 26)))
                        .fontWeight(.regular)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .padding(.horizontal, isVeryCompact ? 20 : (isCompact ? 22 : 24))
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 15)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)
                    
                    // Subtitle
                    Text("Your review helps others discover God's Word.")
                        .font(.system(size: isVeryCompact ? 12 : (isCompact ? 13 : 14), weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .multilineTextAlignment(.center)
                        .lineSpacing(isVeryCompact ? 3 : (isCompact ? 3 : 4))
                        .padding(.horizontal, isVeryCompact ? 30 : (isCompact ? 35 : 40))
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.15), value: animateIn)
                    
                    // Review button / Loading / Thank you
                    switch reviewState {
                    case .idle:
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            
                            withAnimation(.easeInOut(duration: 0.2)) {
                                reviewState = .loading
                            }
                            
                            // Show the App Store review prompt
                            requestReview()
                            
                            // Transition to thank you after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    reviewState = .completed
                                }
                            }
                        }) {
                            Text("Yes, I'll leave a review")
                                .font(.system(size: isVeryCompact ? 14 : (isCompact ? 15 : 16), weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, isVeryCompact ? 28 : (isCompact ? 30 : 32))
                                .padding(.vertical, isVeryCompact ? 14 : (isCompact ? 15 : 16))
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
                            CrownLoadingView(size: 16, tint: .gray)
                            Text("Loading...")
                                .font(.system(size: isVeryCompact ? 14 : (isCompact ? 15 : 16), weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, isVeryCompact ? 28 : (isCompact ? 30 : 32))
                        .padding(.vertical, isVeryCompact ? 14 : (isCompact ? 15 : 16))
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.15))
                        )
                        .transition(.opacity)
                        
                    case .completed:
                        Text("Thank you.")
                            .font(.system(size: isVeryCompact ? 14 : (isCompact ? 15 : 16), weight: .medium))
                            .foregroundColor(.black)
                            .transition(.opacity)
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateIn = true
            }
        }
        .onDisappear {
            // Only mark review as complete when scrolling away AFTER they clicked yes
            if reviewState == .completed {
                hasLeftReview = true
            }
            animateIn = false
        }
    }
}

// MARK: - Share Card View (for main scroll)
struct ShareCardView: View {
    @State private var animateIn = false
    @State private var showingShareSheet = false
    @State private var buttonPressed = false
    @State private var showCheckmark = false
    @State private var iconBounce = false
    @State private var pulseRing = false
    
    // App Store URL for sharing
    private let appStoreURL = "https://apps.apple.com/app/scroll-the-bible/id6745408638"
    
    // Fun, hook-y headlines that rotate randomly
    private let headlines: [(main: String, sub: String)] = [
        ("Your friend needs this.", "Trust us. Send it."),
        ("Be that friend.", "The one who shares the good stuff."),
        ("Plot twist:", "You're about to make someone's day."),
        ("Someone you know\nis doom-scrolling rn.", "Send them something better."),
        ("Hot take:", "This app > everything else in their feed."),
        ("Real ones share.", "Just saying."),
        ("POV:", "You just found their new favorite app."),
        ("One tap.", "Eternal impact. No pressure."),
        ("Send this to your\ngroup chat.", "Watch what happens."),
        ("Your move.", "Someone's waiting for this."),
    ]
    
    // Pick a random headline on each appearance
    @State private var currentHeadline: (main: String, sub: String) = ("", "")
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700
            let isVeryCompact = geometry.size.height < 650
            
            ZStack {
                Color.white
                
                VStack(spacing: isVeryCompact ? 18 : (isCompact ? 22 : 28)) {
                    Spacer()
                    
                    // Animated share icon with pulse ring
                    ZStack {
                        // Pulse ring animation
                        Circle()
                            .stroke(Color.black.opacity(0.1), lineWidth: 2)
                            .frame(width: isVeryCompact ? 70 : (isCompact ? 80 : 90),
                                   height: isVeryCompact ? 70 : (isCompact ? 80 : 90))
                            .scaleEffect(pulseRing ? 1.3 : 1)
                            .opacity(pulseRing ? 0 : 0.6)
                        
                        // Share icon with bounce
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: isVeryCompact ? 34 : (isCompact ? 40 : 46), weight: .medium))
                            .foregroundColor(.black)
                            .offset(y: iconBounce ? -3 : 0)
                    }
                    .opacity(animateIn ? 1 : 0)
                    .scaleEffect(animateIn ? 1 : 0.7)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateIn)
                    
                    // Main hook text
                    Text(currentHeadline.main)
                        .font(.custom("Georgia", size: isVeryCompact ? 22 : (isCompact ? 24 : 26)))
                        .fontWeight(.regular)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .lineSpacing(4)
                        .padding(.horizontal, isVeryCompact ? 24 : (isCompact ? 28 : 32))
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 15)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)
                    
                    // Subtitle
                    Text(currentHeadline.sub)
                        .font(.system(size: isVeryCompact ? 12 : (isCompact ? 13 : 14), weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(0.5)
                        .multilineTextAlignment(.center)
                        .lineSpacing(isVeryCompact ? 3 : (isCompact ? 3 : 4))
                        .padding(.horizontal, isVeryCompact ? 30 : (isCompact ? 35 : 40))
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.15), value: animateIn)
                    
                    // Animated Share button
                    Button(action: {
                        triggerShareAnimation()
                    }) {
                        ZStack {
                            // Background capsule with scale animation
                            Capsule()
                                .fill(showCheckmark ? Color.black.opacity(0.9) : Color.black)
                                .scaleEffect(buttonPressed ? 0.92 : 1)
                            
                            // Content
                            HStack(spacing: 8) {
                                if showCheckmark {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: isVeryCompact ? 14 : (isCompact ? 15 : 16), weight: .semibold))
                                        .foregroundColor(.white)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Text("Send it")
                                        .font(.system(size: isVeryCompact ? 14 : (isCompact ? 15 : 16), weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(width: isVeryCompact ? 130 : (isCompact ? 140 : 150),
                               height: isVeryCompact ? 46 : (isCompact ? 50 : 54))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: animateIn)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonPressed)
                    .animation(.easeInOut(duration: 0.2), value: showCheckmark)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            // Pick a random headline
            currentHeadline = headlines.randomElement() ?? headlines[0]
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateIn = true
            }
            
            // Start subtle icon bounce loop
            startIconBounce()
            
            // Start pulse ring animation
            startPulseAnimation()
        }
        .onDisappear {
            animateIn = false
            iconBounce = false
            pulseRing = false
            showCheckmark = false
            buttonPressed = false
        }
        .sheet(isPresented: $showingShareSheet) {
            AppShareSheet(items: [URL(string: appStoreURL)!])
        }
    }
    
    private func triggerShareAnimation() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Button press animation
        withAnimation(.easeInOut(duration: 0.1)) {
            buttonPressed = true
        }
        
        // Release and show checkmark
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                buttonPressed = false
                showCheckmark = true
            }
            
            // Success haptic
            let success = UINotificationFeedbackGenerator()
            success.notificationOccurred(.success)
        }
        
        // Show share sheet after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showingShareSheet = true
            
            // Reset checkmark after sheet appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    showCheckmark = false
                }
            }
        }
    }
    
    private func startIconBounce() {
        // Subtle floating animation for the icon
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            iconBounce = true
        }
    }
    
    private func startPulseAnimation() {
        // Pulse ring animation that repeats
        withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
            pulseRing = true
        }
    }
}

// MARK: - App Share Sheet (UIKit wrapper)
struct AppShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Paywall Card Components
struct PaywallCardFeatureRow: View {
    let text: String
    var isCompact: Bool = false
    var isVeryCompact: Bool = false
    
    var body: some View {
        HStack(spacing: isVeryCompact ? 10 : (isCompact ? 11 : 12)) {
            Image(systemName: "checkmark")
                .font(.system(size: isVeryCompact ? 10 : (isCompact ? 11 : 12), weight: .bold))
                .foregroundColor(.black)
            
            Text(text)
                .font(.system(size: isVeryCompact ? 13 : (isCompact ? 14 : 15), weight: .regular))
                .foregroundColor(.black.opacity(0.8))
            
            Spacer()
        }
        .padding(.horizontal, isVeryCompact ? 36 : (isCompact ? 40 : 44))
    }
}

struct PaywallCardFreeTrialToggle: View {
    @Binding var withFreeTrial: Bool
    var isCompact: Bool = false
    var isVeryCompact: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Pay Now option (left)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    withFreeTrial = false
                }
            }) {
                Text("Pay Now")
                    .font(.system(size: isVeryCompact ? 12 : (isCompact ? 13 : 14), weight: .medium))
                    .foregroundColor(withFreeTrial ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isVeryCompact ? 10 : (isCompact ? 11 : 12))
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
                    .font(.system(size: isVeryCompact ? 12 : (isCompact ? 13 : 14), weight: .medium))
                    .foregroundColor(withFreeTrial ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isVeryCompact ? 10 : (isCompact ? 11 : 12))
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

struct PaywallCardSubscriptionOption: View {
    let plan: PaywallCardView.PaywallPlan
    let isSelected: Bool
    let withFreeTrial: Bool
    var isCompact: Bool = false
    var isVeryCompact: Bool = false
    let onSelect: () -> Void
    let getPrice: (PaywallCardView.PaywallPlan, Bool) -> String
    let getSavings: (PaywallCardView.PaywallPlan, Bool) -> String?
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.black : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: isVeryCompact ? 18 : (isCompact ? 20 : 22), height: isVeryCompact ? 18 : (isCompact ? 20 : 22))
                    
                    if isSelected {
                        Circle()
                            .fill(Color.black)
                            .frame(width: isVeryCompact ? 10 : (isCompact ? 11 : 12), height: isVeryCompact ? 10 : (isCompact ? 11 : 12))
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(plan == .yearly ? "Annual" : "Monthly")
                            .font(.system(size: isVeryCompact ? 14 : (isCompact ? 15 : 16), weight: .medium))
                            .foregroundColor(.black)
                        
                        if let savings = getSavings(plan, withFreeTrial) {
                            Text(savings)
                                .font(.system(size: isVeryCompact ? 9 : (isCompact ? 10 : 11), weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, isVeryCompact ? 6 : (isCompact ? 7 : 8))
                                .padding(.vertical, isVeryCompact ? 2 : 3)
                                .background(
                                    Capsule()
                                        .fill(Color.black)
                                )
                        }
                    }
                }
                
                Spacer()
                
                // Price
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(plan == .yearly ? (withFreeTrial ? "$2.49" : "$1.67") : getPrice(plan, withFreeTrial))
                        .font(.system(size: isVeryCompact ? 16 : (isCompact ? 17 : 18), weight: .semibold))
                        .foregroundColor(.black)
                    Text("/month")
                        .font(.system(size: isVeryCompact ? 10 : (isCompact ? 11 : 12), weight: .regular))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, isVeryCompact ? 14 : (isCompact ? 16 : 18))
            .padding(.vertical, isVeryCompact ? 12 : (isCompact ? 14 : 16))
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

// MARK: - Next Chapter Trigger View
struct NextChapterTriggerView: View {
    let currentBook: String
    let currentChapter: Int
    let books: [Book]
    @Binding var isLoading: Bool
    let onTrigger: () -> Void
    @State private var hasTriggered = false
    @State private var animateIn = false
    @State private var fadeOut = false
    
    // Calculate what comes next
    private var nextDestination: (isNewBook: Bool, bookName: String, chapter: Int)? {
        guard let currentBookData = books.first(where: { $0.name == currentBook }) else { return nil }
        
        if currentChapter < currentBookData.chapters {
            // Next chapter in same book
            return (isNewBook: false, bookName: currentBook, chapter: currentChapter + 1)
        } else {
            // Move to next book
            if let currentIndex = books.firstIndex(where: { $0.name == currentBook }),
               currentIndex < books.count - 1 {
                let nextBook = books[currentIndex + 1]
                return (isNewBook: true, bookName: nextBook.name, chapter: 1)
            }
        }
        return nil // End of Bible
    }
    
    var body: some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .global)
            // Trigger when the view is settled on screen (top is near screen top)
            let isSettled = frame.minY >= -10 && frame.minY <= 100
            
            ZStack {
                Color.white
                
                if let destination = nextDestination {
                    VStack(spacing: 12) {
                        Text("Continuing onto")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(0.5)
                        
                        if destination.isNewBook {
                            // Going to a new book
                            Text(destination.bookName)
                                .font(.custom("Georgia", size: 28))
                                .fontWeight(.regular)
                                .foregroundColor(.black)
                        } else {
                            // Going to next chapter in same book
                            Text("\(currentBook) \(destination.chapter)")
                                .font(.custom("Georgia", size: 28))
                                .fontWeight(.regular)
                                .foregroundColor(.black)
                        }
                    }
                    .opacity(animateIn && !fadeOut ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4), value: animateIn)
                    .animation(.easeInOut(duration: destination.isNewBook ? 2.4 : 1.2), value: fadeOut)
                } else {
                    // End of Bible
                    VStack(spacing: 12) {
                        Text("You've reached the end")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(0.5)
                        
                        Text("Revelation 22")
                            .font(.custom("Georgia", size: 28))
                            .fontWeight(.regular)
                            .foregroundColor(.black)
                    }
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4), value: animateIn)
                }
            }
            .onChange(of: isSettled) { oldValue, newValue in
                if newValue && !oldValue && !hasTriggered && !isLoading {
                    if let destination = nextDestination {
                        hasTriggered = true
                        triggerWithFade(isNewBook: destination.isNewBook)
                    }
                }
            }
            .onAppear {
                // Animate in the content
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateIn = true
                }
                
                if isSettled && !hasTriggered && !isLoading {
                    if let destination = nextDestination {
                        hasTriggered = true
                        triggerWithFade(isNewBook: destination.isNewBook)
                    }
                }
            }
            .onDisappear {
                animateIn = false
                fadeOut = false
            }
        }
    }
    
    private func triggerWithFade(isNewBook: Bool) {
        // Fade duration: 2.4s for new book, 1.2s for new chapter
        let fadeDuration = isNewBook ? 2.4 : 1.2
        
        // Wait a moment to let user see the message, then fade out and load
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                fadeOut = true
            }
            // After fade out completes, trigger the chapter load
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
                onTrigger()
            }
        }
    }
}

#Preview {
    MainScrollView(viewModel: BibleViewModel(), authService: AuthService())
        .modelContainer(for: [Favorite.self, Note.self], inMemory: true)
}
