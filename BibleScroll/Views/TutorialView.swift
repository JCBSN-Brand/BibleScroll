//
//  TutorialView.swift
//  BibleScroll
//
//  Interactive tutorial overlay for first-time users
//

import SwiftUI

// MARK: - Tutorial Step Model
enum TutorialStep: Int, CaseIterable {
    case welcome
    case scrolling
    case likeButton
    case commentButton
    case shareButton
    case bookPicker
    case translationPicker
    case viewSaved
    case complete
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Bible Scroll"
        case .scrolling:
            return "Swipe to Explore"
        case .likeButton:
            return "Save Your Favorites"
        case .commentButton:
            return "Add Personal Notes"
        case .shareButton:
            return "Share the Word"
        case .bookPicker:
            return "Navigate Scripture"
        case .translationPicker:
            return "Choose Translation"
        case .viewSaved:
            return "Your Collection"
        case .complete:
            return "You're All Set!"
        }
    }
    
    var description: String {
        switch self {
        case .welcome:
            return "Let's take a quick tour to help you get the most out of your Bible reading."
        case .scrolling:
            return "Swipe up or down to move through verses."
        case .likeButton:
            return "Tap to save verses you love.\nDouble-tap anywhere for a quick like!"
        case .commentButton:
            return "Add your personal reflections and study notes."
        case .shareButton:
            return "Share inspiring verses with others."
        case .bookPicker:
            return "Jump to any book and chapter."
        case .translationPicker:
            return "Switch Bible versions."
        case .viewSaved:
            return "View your saved verses and notes."
        case .complete:
            return "Start exploring God's Word!"
        }
    }
    
    var hasSpotlight: Bool {
        switch self {
        case .welcome, .scrolling, .complete:
            return false
        default:
            return true
        }
    }
}

// MARK: - Tutorial View
struct TutorialView: View {
    @Binding var isShowingTutorial: Bool
    @State private var currentStep: TutorialStep = .welcome
    @State private var animateContent = false
    @State private var pulseAnimation = false
    
    // Button dimensions (must match ActionButtonsView)
    private let buttonSize: CGFloat = 46
    private let buttonSpacing: CGFloat = 20
    private let trailingPadding: CGFloat = 16
    private let bottomPadding: CGFloat = 120
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let safeTop = geometry.safeAreaInsets.top
            let safeBottom = geometry.safeAreaInsets.bottom
            
            ZStack {
                // Dimmed background
                Color.black.opacity(0.75)
                    .ignoresSafeArea()
                
                // Spotlight cutout
                if currentStep.hasSpotlight {
                    SpotlightCutout(
                        spotlight: getSpotlight(
                            screenWidth: screenWidth,
                            screenHeight: screenHeight,
                            safeTop: safeTop,
                            safeBottom: safeBottom
                        ),
                        pulseAnimation: pulseAnimation
                    )
                    .ignoresSafeArea()
                }
                
                // Tutorial text positioned near the element
                TutorialText(
                    step: currentStep,
                    animateContent: animateContent,
                    textPosition: getTextPosition(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        safeTop: safeTop,
                        safeBottom: safeBottom
                    ),
                    onNext: nextStep,
                    onSkip: skipTutorial
                )
                
                // Swipe hint for scrolling step
                if currentStep == .scrolling {
                    SwipeGestureHint()
                        .position(x: screenWidth / 2, y: screenHeight * 0.65)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                animateContent = true
            }
            startPulseAnimation()
        }
    }
    
    private func getSpotlight(screenWidth: CGFloat, screenHeight: CGFloat, safeTop: CGFloat, safeBottom: CGFloat) -> SpotlightRect {
        // Action button positions (from bottom-right)
        // Buttons are 46x46 with 20 spacing, trailing 16, bottom 120
        let actionX = screenWidth - trailingPadding - buttonSize / 2
        
        // Calculate Y positions for action buttons
        // VStack: Like (top), Comment (middle), Share (bottom)
        // Total height = 46 + 20 + 46 + 20 + 46 = 178
        let vstackHeight = buttonSize * 3 + buttonSpacing * 2
        let vstackBottom = screenHeight - bottomPadding + safeBottom
        let vstackTop = vstackBottom - vstackHeight
        
        let likeY = vstackTop + buttonSize / 2
        let commentY = likeY + buttonSize + buttonSpacing
        let shareY = commentY + buttonSize + buttonSpacing
        
        // Nav bar button position
        let navY = safeTop + 10 + 21 // padding + half button height
        
        switch currentStep {
        case .likeButton:
            return SpotlightRect(x: actionX, y: likeY, size: 54)
            
        case .commentButton:
            return SpotlightRect(x: actionX, y: commentY, size: 54)
            
        case .shareButton:
            return SpotlightRect(x: actionX, y: shareY, size: 54)
            
        case .bookPicker:
            return SpotlightRect(x: screenWidth / 2, y: navY, width: 130, height: 44, cornerRadius: 22)
            
        case .translationPicker:
            // After search button: 16 + 42 + 8 + 25
            let transX: CGFloat = 16 + 42 + 8 + 25
            return SpotlightRect(x: transX, y: navY, width: 52, height: 40, cornerRadius: 20)
            
        case .viewSaved:
            // Notes + Favorites on right
            let centerX = screenWidth - 16 - 42 - 4
            return SpotlightRect(x: centerX, y: navY, width: 96, height: 48, cornerRadius: 24)
            
        default:
            return SpotlightRect(x: 0, y: 0, size: 0)
        }
    }
    
    private func getTextPosition(screenWidth: CGFloat, screenHeight: CGFloat, safeTop: CGFloat, safeBottom: CGFloat) -> CGPoint {
        switch currentStep {
        case .welcome, .complete:
            return CGPoint(x: screenWidth / 2, y: screenHeight / 2)
            
        case .scrolling:
            return CGPoint(x: screenWidth / 2, y: screenHeight * 0.35)
            
        case .likeButton, .commentButton, .shareButton:
            // Position text to the left of the action buttons, vertically centered with them
            let actionX = screenWidth - trailingPadding - buttonSize / 2
            let vstackHeight = buttonSize * 3 + buttonSpacing * 2
            let vstackBottom = screenHeight - bottomPadding + safeBottom
            let vstackCenter = vstackBottom - vstackHeight / 2
            
            return CGPoint(x: (screenWidth - actionX) / 2 + 20, y: vstackCenter)
            
        case .bookPicker:
            // Below the book picker
            return CGPoint(x: screenWidth / 2, y: safeTop + 120)
            
        case .translationPicker:
            // Below and slightly right of translation
            return CGPoint(x: screenWidth * 0.35, y: safeTop + 120)
            
        case .viewSaved:
            // Below the buttons on the right
            return CGPoint(x: screenWidth - 100, y: safeTop + 120)
        }
    }
    
    private func nextStep() {
        let allSteps = TutorialStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex < allSteps.count - 1 {
            withAnimation(.easeOut(duration: 0.15)) {
                animateContent = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                currentStep = allSteps[currentIndex + 1]
                withAnimation(.easeOut(duration: 0.2)) {
                    animateContent = true
                }
            }
        } else {
            completeTutorial()
        }
    }
    
    private func skipTutorial() {
        completeTutorial()
    }
    
    private func completeTutorial() {
        withAnimation(.easeOut(duration: 0.2)) {
            isShowingTutorial = false
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
}

// MARK: - Spotlight Rectangle
struct SpotlightRect {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(x: CGFloat, y: CGFloat, size: CGFloat) {
        self.x = x
        self.y = y
        self.width = size
        self.height = size
        self.cornerRadius = size / 2
    }
    
    init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, cornerRadius: CGFloat) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
}

// MARK: - Spotlight Cutout
struct SpotlightCutout: View {
    let spotlight: SpotlightRect
    let pulseAnimation: Bool
    
    var body: some View {
        ZStack {
            // Use Canvas to cut out the spotlight area
            Canvas { context, size in
                // Draw dim overlay
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(.black.opacity(0.75))
                )
                
                // Cut out spotlight
                context.blendMode = .destinationOut
                let rect = CGRect(
                    x: spotlight.x - spotlight.width / 2,
                    y: spotlight.y - spotlight.height / 2,
                    width: spotlight.width,
                    height: spotlight.height
                )
                let path = RoundedRectangle(cornerRadius: spotlight.cornerRadius)
                    .path(in: rect)
                context.fill(path, with: .color(.white))
            }
            .compositingGroup()
            
            // Glow ring
            RoundedRectangle(cornerRadius: spotlight.cornerRadius + 2)
                .stroke(Color.white.opacity(0.9), lineWidth: 2)
                .frame(width: spotlight.width + 4, height: spotlight.height + 4)
                .position(x: spotlight.x, y: spotlight.y)
                .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                .opacity(pulseAnimation ? 0.6 : 1.0)
        }
    }
}

// MARK: - Tutorial Text
struct TutorialText: View {
    let step: TutorialStep
    let animateContent: Bool
    let textPosition: CGPoint
    let onNext: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress dots
            HStack(spacing: 5) {
                ForEach(0..<TutorialStep.allCases.count, id: \.self) { index in
                    Circle()
                        .fill(index == step.rawValue ? Color.white : Color.white.opacity(0.3))
                        .frame(width: index == step.rawValue ? 7 : 5, height: index == step.rawValue ? 7 : 5)
                }
            }
            .padding(.bottom, 4)
            
            // Title
            Text(step.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Description
            Text(step.description)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            
            // Buttons
            HStack(spacing: 20) {
                if step != .welcome && step != .complete {
                    Button(action: onSkip) {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Button(action: onNext) {
                    HStack(spacing: 5) {
                        Text(step == .complete ? "Get Started" : (step == .welcome ? "Start" : "Next"))
                            .font(.system(size: 15, weight: .semibold))
                        if step != .complete {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(Color.white))
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 280)
        .position(textPosition)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 15)
    }
}

// MARK: - Swipe Gesture Hint
struct SwipeGestureHint: View {
    @State private var animating = false
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "hand.point.up.fill")
                .font(.system(size: 36))
                .foregroundColor(.white)
                .offset(y: animating ? -45 : 0)
                .opacity(animating ? 0 : 1)
            
            Text("Swipe Up")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                animating = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.white
        Text("Content")
    }
    .overlay(
        TutorialView(isShowingTutorial: .constant(true))
    )
}
