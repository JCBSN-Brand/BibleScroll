//
//  VerseCardView.swift
//  BibleScroll
//
//  Minimalist verse display card with action buttons on the right
//

import SwiftUI

// Individual heart for animation
struct AnimatedHeart: Identifiable {
    let id = UUID()
    let position: CGPoint
    let rotation: Double      // Slight random tilt for variety
    let targetPosition: CGPoint  // Where the heart should fly to (crown)
}

// Crown button with touch-responsive animation and haptics
struct CrownButton: View {
    let action: () -> Void
    @Binding var heartImpactScale: CGFloat  // External control for heart slam impact
    var showHint: Bool = false  // Shows pulsing hint after dwelling on verse
    
    @State private var scale: CGFloat = 1.0
    @State private var isTouching = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 8) {
            Image("crown-icon")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 82, height: 82)
                .foregroundColor(.black)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                )
                .scaleEffect(scale * heartImpactScale * pulseScale)  // Combine all scales
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            // Only shrink on first touch (prevent multiple shrinks during drag)
                            if !isTouching {
                                isTouching = true
                                
                                // Haptic on touch down
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                // Shrink down (less dramatic)
                                withAnimation(.easeInOut(duration: 0.08)) {
                                    scale = 0.85
                                }
                            }
                        }
                        .onEnded { _ in
                            isTouching = false
                            
                            // Ensure shrink completes THEN bounce back
                            // Wait for shrink to finish (0.08s) before bouncing
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                                // Haptic on release
                                let releaseFeedback = UIImpactFeedbackGenerator(style: .light)
                                releaseFeedback.impactOccurred()
                                
                                // Bounce back up with spring (snappier)
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                                    scale = 1.0
                                }
                                
                                // Execute action
                                action()
                            }
                        }
                )
            
            // "Click me" hint text
            if showHint {
                Text("Click me")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray.opacity(0.7))
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .onChange(of: showHint) { _, isShowing in
            if isShowing {
                startPulseAnimation()
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    pulseScale = 1.0
                }
            }
        }
    }
    
    private func startPulseAnimation() {
        // Gentle pulse animation
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.06
        }
    }
}

struct HeartAnimationView: View {
    let heart: AnimatedHeart
    let size: CGFloat
    let onImpact: () -> Void   // Called when heart reaches the crown
    let onComplete: () -> Void
    
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0
    @State private var currentPosition: CGPoint = .zero
    
    var body: some View {
        Image("bxs-heart")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundColor(.red)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(heart.rotation))
            .position(currentPosition)
            .onAppear {
                currentPosition = heart.position
                
                // Phase 1: Quick spring pop with overshoot (0.6 → 1.2)
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5, blendDuration: 0)) {
                    scale = 1.2
                    opacity = 1.0
                }
                
                // Phase 2: Settle to normal size (1.2 → 1.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                        scale = 1.0
                    }
                }
                
                // Phase 3: SLAM DUNK - fly toward the crown with a curve!
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Shrink while flying
                    withAnimation(.easeIn(duration: 0.35)) {
                        scale = 0.4
                        currentPosition = heart.targetPosition
                    }
                    
                    // Fade out right at impact
                    withAnimation(.easeIn(duration: 0.35).delay(0.2)) {
                        opacity = 0
                    }
                    
                    // Trigger impact when heart arrives at crown
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                        onImpact()
                    }
                    
                    // Cleanup after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        onComplete()
                    }
                }
            }
    }
}

// Coordinate space for tracking crown position
private let verseCardCoordinateSpace = "VerseCardSpace"

struct VerseCardView: View {
    let verse: Verse
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    @State private var showingNotes = false
    @State private var showingAIStudy = false
    @State private var noteText = ""
    @State private var animatedHearts: [AnimatedHeart] = []
    @State private var crownPosition: CGPoint = .zero  // Track where crown is
    @State private var crownImpactScale: CGFloat = 1.0  // For slam dunk bounce
    @State private var showCrownHint = false  // Shows "Click me" after 3s dwell
    @State private var dwellTimer: Timer? = nil
    
    // Hide crown button for Esther 8:9 (longest verse in the Bible - needs full screen space)
    private var shouldHideCrown: Bool {
        verse.book == "Esther" && verse.chapter == 8 && verse.verseNumber == 9
    }
    
    var body: some View {
        ZStack {
            // Content area with double-tap gesture (NOT including buttons)
            ZStack {
                // Pure white background
                Color.white
                
                // Centered verse content
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Verse text - centered on screen (supports red letter for Jesus's words)
                    Text(RedLetterText.parse(verse.text, fontSize: dynamicFontSize(for: verse.text)))
                        .fontWeight(.regular)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                    
                    // Reference
                    Text(verse.reference)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    Spacer()
                }
                
                // Multiple hearts animation overlay (shown on double-tap at tap location)
                ForEach(animatedHearts) { heart in
                    HeartAnimationView(
                        heart: heart,
                        size: 100,
                        onImpact: {
                            triggerCrownImpact()
                        },
                        onComplete: {
                            animatedHearts.removeAll { $0.id == heart.id }
                        }
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture(count: 2)
                    .onEnded { event in
                        doubleTapToLike(at: event.location)
                    }
            )
            
            // Crown button - centered below header (AI Study)
            // Hidden for Esther 8:9 (longest verse) to give full screen space
            if !shouldHideCrown {
                VStack {
                    CrownButton(
                        action: {
                            // Hide hint when tapped
                            showCrownHint = false
                            dwellTimer?.invalidate()
                            dwellTimer = nil
                            showingAIStudy = true
                        },
                        heartImpactScale: $crownImpactScale,
                        showHint: showCrownHint
                    )
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    // Get the center of the crown button in the coordinate space
                                    let frame = geo.frame(in: .named(verseCardCoordinateSpace))
                                    crownPosition = CGPoint(x: frame.midX, y: frame.midY)
                                }
                        }
                    )
                .padding(.top, 145)
                .animation(.easeOut(duration: 0.3), value: showCrownHint)
                    
                    Spacer()
                }
            }
            
            // Action buttons OUTSIDE of double-tap gesture area - instant response
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    ActionButtonsView(
                        verse: verse,
                        favoritesViewModel: favoritesViewModel,
                        onNoteTap: {
                            showingNotes = true
                        }
                    )
                    .padding(.trailing, 16)
                }
                .padding(.bottom, 120)
            }
        }
        .coordinateSpace(name: verseCardCoordinateSpace)
        .sheet(isPresented: $showingNotes) {
            NotesSheetView(
                verse: verse,
                noteText: $noteText,
                onSave: {
                    favoritesViewModel.saveNote(verseId: verse.verseId, content: noteText)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .onAppear {
                // Load note after sheet appears (non-blocking)
                noteText = favoritesViewModel.getNote(verseId: verse.verseId) ?? ""
            }
        }
        .sheet(isPresented: $showingAIStudy) {
            AIStudyView(verse: verse, isPresented: $showingAIStudy)
                .environmentObject(subscriptionService)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            startDwellTimer()
        }
        .onDisappear {
            dwellTimer?.invalidate()
            dwellTimer = nil
            showCrownHint = false
        }
    }
    
    // Start a timer to show "Click me" hint after 3 seconds
    private func startDwellTimer() {
        dwellTimer?.invalidate()
        showCrownHint = false
        
        dwellTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                showCrownHint = true
            }
        }
    }
    
    // Trigger the crown "got hit" bounce effect
    private func triggerCrownImpact() {
        // Heavy haptic for the slam dunk impact
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Squish down on impact
        withAnimation(.easeOut(duration: 0.08)) {
            crownImpactScale = 0.85
        }
        
        // Bounce back up with overshoot
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                crownImpactScale = 1.0
            }
        }
    }
    
    // Double-tap to like/favorite at specific location
    private func doubleTapToLike(at location: CGPoint) {
        // Add to favorites (if not already favorited, this will add it; if already favorited, we still show the animation)
        if !favoritesViewModel.isFavorite(verse) {
            favoritesViewModel.toggleFavorite(verse)
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Create heart at tap location, targeting the crown
        let randomRotation = Double.random(in: -15...15)
        let newHeart = AnimatedHeart(position: location, rotation: randomRotation, targetPosition: crownPosition)
        animatedHearts.append(newHeart)
    }
    
    // Dynamic font size based on text length
    private func dynamicFontSize(for text: String) -> CGFloat {
        let length = text.count
        
        if length > 300 {
            return 18
        } else if length > 200 {
            return 20
        } else if length > 100 {
            return 22
        } else {
            return 26
        }
    }
}

#Preview {
    VerseCardView(
        verse: Verse.sampleVerses[0],
        favoritesViewModel: FavoritesViewModel()
    )
    .environmentObject(SubscriptionService())
}
