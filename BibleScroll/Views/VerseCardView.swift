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
    let driftDirection: CGFloat  // Random left/right drift when floating up
}

// Crown button with touch-responsive animation and haptics
struct CrownButton: View {
    let action: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var isTouching = false
    
    var body: some View {
        Image("crown-icon")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 90, height: 90)
            .foregroundColor(.black)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .scaleEffect(scale)
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
    }
}

struct HeartAnimationView: View {
    let heart: AnimatedHeart
    let size: CGFloat
    let onComplete: () -> Void
    
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0
    @State private var xOffset: CGFloat = 0
    @State private var yOffset: CGFloat = 0
    
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
            .offset(x: xOffset, y: yOffset)
            .position(heart.position)
            .onAppear {
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
                
                // Phase 3: Exit - float up with drift, fade out, scale down
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeOut(duration: 0.7)) {
                        yOffset = -90
                        xOffset = heart.driftDirection * 1.3
                        opacity = 0
                        scale = 0.8
                    }
                    
                    // Cleanup after exit animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        onComplete()
                    }
                }
            }
    }
}

struct VerseCardView: View {
    let verse: Verse
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    @ObservedObject var authService: AuthService
    
    @State private var showingNotes = false
    @State private var showingAIStudy = false
    @State private var noteText = ""
    @State private var animatedHearts: [AnimatedHeart] = []
    
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
                    HeartAnimationView(heart: heart, size: 100) {
                        animatedHearts.removeAll { $0.id == heart.id }
                    }
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
            VStack {
                CrownButton(action: {
                    showingAIStudy = true
                })
                .padding(.top, 160)
                
                Spacer()
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
            AIStudyView(verse: verse, isPresented: $showingAIStudy, authService: authService)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
        
        // Create heart at tap location with slight random rotation and drift
        let randomRotation = Double.random(in: -15...15)
        let randomDrift = CGFloat.random(in: -25...25)  // Drift left or right as it floats up
        let newHeart = AnimatedHeart(position: location, rotation: randomRotation, driftDirection: randomDrift)
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
        favoritesViewModel: FavoritesViewModel(),
        authService: AuthService()
    )
}
