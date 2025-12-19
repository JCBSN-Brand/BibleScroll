# Bible Scroll - Complete UI/UX Design Guide

This is an ultra-comprehensive guide documenting every visual and interaction detail of the Bible Scroll app. Use this to recreate the exact same look and feel for a new app with different core functionality.

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Color System](#color-system)
3. [Typography](#typography)
4. [Layout & Spacing](#layout--spacing)
5. [Component Library](#component-library)
6. [Animations & Transitions](#animations--transitions)
7. [Haptic Feedback](#haptic-feedback)
8. [Icons & Assets](#icons--assets)
9. [Screen-by-Screen Breakdown](#screen-by-screen-breakdown)
10. [Responsive Design](#responsive-design)
11. [SwiftUI Implementation Patterns](#swiftui-implementation-patterns)

---

## Design Philosophy

### Core Principles
- **Ultra-minimalist**: White background dominates, black text, minimal visual noise
- **TikTok-style scrolling**: Full-screen vertical paging with snapping
- **Light mode only**: Forces `.preferredColorScheme(.light)`
- **Floating elements**: Buttons and headers "float" with subtle shadows
- **Content-first**: Maximum focus on the primary content

### Aesthetic
- Clean, modern, almost sterile
- High contrast (black on white)
- Subtle depth through shadows (no heavy 3D effects)
- Elegant serif for content, system sans-serif for UI
- Smooth, deliberate animations

---

## Color System

### Primary Colors

| Color Name | SwiftUI | Hex Equivalent | Usage |
|------------|---------|----------------|-------|
| Background | `Color.white` | `#FFFFFF` | All backgrounds |
| Primary Text | `Color.black` | `#000000` | Main text, icons, buttons |
| Secondary Text | `Color.gray` | `#8E8E93` | Subtitles, references, hints |
| Tertiary Text | `Color.gray.opacity(0.7)` | ~`#8E8E93B3` | Light hints, disabled |
| Light Gray Text | `Color.gray.opacity(0.6)` | ~`#8E8E9399` | Very subtle hints |
| Accent Red | `Color.red` | `#FF3B30` | Heart/favorite active state |
| Jesus Words Red | `Color(red: 0.8, green: 0.1, blue: 0.1)` | `#CC1A1A` | Red letter text |
| Success Green | `Color.green` | `#34C759` | "Offline" badge |

### Shadow Colors

| Shadow Type | Color | Radius | X | Y |
|-------------|-------|--------|---|---|
| Header buttons | `Color.black.opacity(0.08)` | 8 | 0 | 2 |
| Action buttons | `Color.black.opacity(0.08)` | 12 | 0 | 4 |
| Tutorial demos | `Color.black.opacity(0.1)` | 12-16 | 0 | 4-6 |
| Crown button | `Color.black.opacity(0.08)` | 12 | 0 | 4 |

### Background Fills

| Usage | Color |
|-------|-------|
| Card background | `Color.gray.opacity(0.05)` |
| Search bar background | `Color.gray.opacity(0.1)` |
| Text editor background | `Color.gray.opacity(0.08)` |
| Section headers | `Color(UIColor.systemGray6)` |
| Toggle inactive bg | `Color.gray.opacity(0.1)` |
| Selected item subtle | `Color.black.opacity(0.03)` |
| Current book row | `Color.black.opacity(0.04)` |
| Chapter grid inactive | `Color.gray.opacity(0.1)` |

### Border/Stroke Colors

| State | Color | Line Width |
|-------|-------|------------|
| Unselected option | `Color.gray.opacity(0.3)` | 1 |
| Selected option | `Color.black` | 2 |
| Radio button inactive | `Color.gray.opacity(0.4)` | 2 |
| Radio button active | `Color.black` | 2 |

---

## Typography

### Font Families

1. **Georgia** (Serif) - For primary content/verses
2. **System (.system())** - For all UI elements

### Text Styles

#### Content Typography

| Element | Font | Size | Weight | Line Spacing | Tracking |
|---------|------|------|--------|--------------|----------|
| Verse text (short <100 chars) | Georgia | 26 | regular | 6 | - |
| Verse text (medium 100-200) | Georgia | 22 | regular | 6 | - |
| Verse text (long 200-300) | Georgia | 20 | regular | 6 | - |
| Verse text (very long >300) | Georgia | 18 | regular | 6 | - |
| Verse reference | System | 14 | medium | - | 1 |
| Tutorial main text | Georgia | 22-26 | regular | 4-6 | - |
| Tutorial subtitle | System | 12-14 | medium | 3-4 | 0.5-1 |
| Paywall title | Georgia | 24-28 | regular | - | - |
| Paywall subtitle | System | 13-15 | medium | - | 0.5 |
| Section subtitle | System | 14-15 | medium | - | 0.5 |

#### UI Typography

| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Navigation title | inline | - | black |
| Header book name | 12 | medium | black |
| Header chapter | 11 | regular | gray |
| Translation badge (header) | 11 | semibold | black |
| Search button icon | 14 | medium | black |
| Book row name | 17 | regular/semibold | black |
| Book row chapters | 14 | regular | gray |
| Section header | 13 | semibold | gray |
| Button "Continue" | 15-17 | semibold | white |
| Button "Cancel" | - | regular | gray |
| Button "Done" | - | semibold | black |
| Chevron icons | 8-12 | medium/semibold | gray |
| Feature checkmarks | 10-12 | bold | black |
| Feature text | 13-15 | regular | black 0.8 |
| Price large | 16-18 | semibold | black |
| Price suffix "/month" | 10-12 | regular | gray |
| Savings badge | 9-11 | bold | white |
| Terms/Privacy | 10-11 | regular | gray 0.7 |
| Restore purchases | 11-13 | medium | gray |
| Empty state title | 18 | medium | gray |
| Empty state subtitle | 14 | regular | gray 0.7 |
| List item | 16-17 | regular | black |
| Notes "Auto-saved" | 12 | regular | gray 0.6 |
| Note date | 12 | regular | gray |

#### Text Case & Tracking

| Element | Text Case | Tracking |
|---------|-----------|----------|
| Section headers | `.uppercase` | 0.5 |
| Verse reference | normal | 1 |
| Paywall subtitle | normal | 0.5 |
| Tutorial hints | normal | 0.5-1 |

---

## Layout & Spacing

### Safe Areas & Padding

```
- Content horizontal padding: 24px (verse text)
- Header horizontal padding: 10px
- Section horizontal padding: 20px
- Card padding: 16px
- List row vertical padding: 14px
- Search bar internal padding: 12px
```

### Header Bar Layout

```
Height: Dynamic (content + safeArea.top + 6pt top + 6pt bottom)
Spacing between button groups: 5px
Spacer minLength: 2px

┌─────────────────────────────────────────────────────────────┐
│  [🔍] [KJV]     [Genesis 1 ▼]         [💬] [❤️]            │
│  ← 5px →        ← Center →            ← 5px →              │
└─────────────────────────────────────────────────────────────┘
```

### Action Buttons Layout (Right Side)

```
Position: Bottom-right
Vertical spacing: 20px between buttons
Trailing padding: 16px
Bottom padding from screen: 120px

┌──────┐
│  ❤️  │
├──────┤
│  💬  │  20px
├──────┤
│  ➤   │  20px
└──────┘
```

### Crown Button Position

```
Position: Top-center, below header
Top padding from content area: 160px
```

### Chapter Grid Layout

```
Columns: 5 (flexible)
Spacing: 12px (both horizontal and vertical)
Cell size: 56x56
Corner radius: 12
Outer padding: 20px
```

### Subscription Options Layout

```
Outer corner radius: 12
Horizontal padding: 14-18px
Vertical padding: 12-16px
Radio button outer: 18-22px
Radio button inner: 10-12px
```

---

## Component Library

### 1. Header Circle Button

```swift
// Shadow: 8 radius, 0.08 opacity, y: 2
// Padding: 11pt
// Background: Circle, white fill
// Content: Icon 14-16pt
```

**Dimensions:**
- Icon size: 14-16pt
- Internal padding: 11pt
- Total approximate size: ~36pt diameter

### 2. Header Capsule Button

```swift
// Shadow: 8 radius, 0.08 opacity, y: 2
// Padding: horizontal 10, vertical 8
// Background: Capsule, white fill
```

### 3. Action Button (Like/Comment/Share)

```swift
// Icon size: 20x20
// Padding: 13pt
// Background: Circle, white fill
// Shadow: 12 radius, 0.08 opacity, y: 4
```

**Total diameter:** ~46pt

### 4. Crown Button

```swift
// Icon size: 90x90
// Padding: 14pt
// Background: RoundedRectangle, 20 corner radius, white fill
// Shadow: 12 radius, 0.08 opacity, y: 4
```

### 5. Search Bar

```swift
// Background: gray.opacity(0.1)
// Corner radius: 12
// Padding: 12pt internal
// Icon: magnifyingglass, gray
// Clear button: xmark.circle.fill, gray
```

### 6. Book Row

```swift
// Current book indicator: 6x6 black circle (or clear)
// Font: 17pt, semibold if current
// Chapters text: 14pt, gray
// Chevron: 12pt, gray.opacity(0.5)
// Padding: horizontal 20, vertical 14
// Background: black.opacity(0.04) if current
```

### 7. Subscription Option Card

```swift
// Border radius: 12
// Stroke: 1px gray.opacity(0.3) unselected, 2px black selected
// Fill: clear or black.opacity(0.03) when selected
// Radio: 18-22pt outer circle, 10-12pt inner fill
// Savings badge: Capsule, black fill, white text
```

### 8. Free Trial Toggle

```swift
// Container: RoundedRectangle, 12 radius, gray.opacity(0.1) fill
// Inner padding: 4pt
// Segment: RoundedRectangle, 10 radius
// Selected: black fill, white text
// Unselected: clear fill, black text
// Animation: easeInOut, 0.2s
```

### 9. Card Container (Favorites/Notes list)

```swift
// Background: RoundedRectangle, 12 radius, gray.opacity(0.05) fill
// Padding: 16pt internal
// Text: Georgia 16pt for verse, System 13-15pt for meta
// Line spacing: 4pt
```

### 10. Section Header (Sticky)

```swift
// Background: Color(UIColor.systemGray6)
// Font: 13pt, semibold, gray
// Text case: uppercase
// Tracking: 0.5
// Padding: horizontal 20, vertical 10
```

### 11. Loading Indicator (Crown)

```swift
// Crown icon rotating
// Animation: linear, 1.2s, repeat forever
// Sizes: 18-60pt depending on context
// Tint: black or white
```

---

## Animations & Transitions

### 1. Main Content Fade-In (After Tutorial)

```swift
.easeInOut(duration: 2.5)
// From opacity 0 to 1
```

### 2. Tutorial/Card Enter Animation

```swift
// Staggered delays: 0.1, 0.15, 0.2, 0.25, 0.3...
// Each element:
.easeOut(duration: 0.4-0.5)
// Opacity: 0 → 1
// Offset Y: 10-20pt → 0
// Scale (icons): 0.8 → 1
```

### 3. Button Press (Fast Pop)

```swift
// Scale: 1.0 → 0.9 → 1.0
.easeOut(duration: 0.1)
```

### 4. Crown Button Press

```swift
// Press down: easeInOut, 0.08s, scale to 0.85
// Release: spring(response: 0.25, dampingFraction: 0.5), scale to 1.0
```

### 5. Heart Animation (Double-tap)

**Phase 1 - Pop:**
```swift
.spring(response: 0.25, dampingFraction: 0.5, blendDuration: 0)
// Scale: 0.6 → 1.2, Opacity: 0 → 1
```

**Phase 2 - Settle (0.15s delay):**
```swift
.spring(response: 0.15, dampingFraction: 0.7)
// Scale: 1.2 → 1.0
```

**Phase 3 - Fly to crown (0.3s delay):**
```swift
.easeIn(duration: 0.35)
// Scale: 1.0 → 0.4
// Position: tap location → crown position
// Opacity fade at end: easeIn, 0.35s, 0.2s delay
```

### 6. Crown Impact (Heart arrives)

```swift
// Squish: easeOut, 0.08s, scale to 0.85
// Bounce: spring(response: 0.3, dampingFraction: 0.4), scale to 1.0
```

### 7. Like Button Toggle

```swift
.spring(response: 0.3, dampingFraction: 0.5)
// Scale: 1.0 → 1.1 → 1.0
```

### 8. Sheet/View Transitions

```swift
// Most: easeInOut, 0.2s
// Navigation push simulation: easeInOut, 0.2s
```

### 9. Paywall Content Cascade

```swift
// Crown: easeOut, 0.5s
// Title: easeOut, 0.4s, delay 0.1
// Subtitle: easeOut, 0.4s, delay 0.15
// Features: easeOut, 0.4s, delay 0.2
// Toggle: easeOut, 0.4s, delay 0.22
// Options: easeOut, 0.4s, delay 0.25
// Button: easeOut, 0.4s, delay 0.3 (also scale 0.95 → 1)
// Restore: easeOut, 0.4s, delay 0.35
// Terms: easeOut, 0.4s, delay 0.4
```

### 10. Next Chapter Fade

```swift
// Text fade out: easeInOut
// Duration: 1.2s for same book, 2.4s for new book
// Content fade in: easeIn, 0.4s
```

### 11. Scroll Hint Bounce

```swift
.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
// Offset Y: 0 → -8
```

### 12. Crown Loading Spinner

```swift
.linear(duration: 1.2).repeatForever(autoreverses: false)
// Rotation: 0° → 360°
```

### 13. Share Icon Float

```swift
.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
// Offset Y: 0 → -3
```

### 14. Pulse Ring (Share Card)

```swift
.easeOut(duration: 1.8).repeatForever(autoreverses: false)
// Scale: 1 → 1.3
// Opacity: 0.6 → 0
```

### 15. Review State Transitions

```swift
.spring(response: 0.4, dampingFraction: 0.7-0.8)
// Scale changes between states
// Crown pulse during loading: easeInOut, 0.8s, repeat, scale 1 → 1.08
```

---

## Haptic Feedback

### Haptic Mapping

| Action | Style | Timing |
|--------|-------|--------|
| Button tap (general) | `.light` | On tap |
| Crown touch down | `.medium` | On touch |
| Crown release | `.light` | On release |
| Purchase button | `.medium` | On tap |
| Heart slam into crown | `.heavy` | On impact |
| Double-tap like | `.light` | On tap |
| Review/Share success | `.success` (notification) | On complete |

---

## Icons & Assets

### Custom Image Assets

Located in `Assets.xcassets`:

| Asset Name | Usage | Rendering |
|------------|-------|-----------|
| `crown-icon` | AI study button, loading, paywall | Template (colorable) |
| `bx-heart` | Like button (outline) | Template |
| `bxs-heart` | Like button (filled) | Template |
| `bx-message` | Notes button (outline) | Template |
| `bxs-message` | Notes button (filled) | Template |
| `bx-send` | Share button | Template |

### System Icons (SF Symbols)

| Icon | Weight | Usage |
|------|--------|-------|
| `magnifyingglass` | medium | Search button |
| `chevron.down` | semibold | Picker dropdown |
| `chevron.left` | medium | Back navigation |
| `chevron.right` | medium | List disclosure |
| `chevron.up` | medium | Scroll hints |
| `xmark.circle.fill` | - | Clear search |
| `checkmark` | bold | Feature rows, selection |
| `checkmark.shield.fill` | medium | Security assurance |
| `checkmark.circle.fill` | - | Completion state |
| `book.closed` | - | Empty state |
| `book` | - | Deeper study mode |
| `lightbulb` | - | Explain mode |
| `link` | - | Related verses mode |
| `star.fill` | - | Review request |
| `square.and.arrow.up` | medium | Share icon |
| `trash` | - | Delete |
| `exclamationmark.circle` | - | Error state |

---

## Screen-by-Screen Breakdown

### 1. Main Scroll View

```
┌────────────────────────────────────┐
│  [🔍] [KJV]   [Book Ch ▼]   [💬][❤]│ ← Floating header
│                                    │
│                                    │
│            [Crown Button]          │
│                                    │
│                                    │
│     "For God so loved the world,   │
│      that he gave his only         │
│      begotten Son..."              │
│                                    │
│           — John 3:16              │
│                                    │
│                              [❤]   │
│                              [💬]  │
│                              [➤]   │
│                                    │
└────────────────────────────────────┘
```

**Characteristics:**
- White background (`Color.white`)
- Paging scroll behavior (`.scrollTargetBehavior(.paging)`)
- No scroll indicators
- Verse centered vertically
- Georgia font for verse text (dynamic size 18-26)
- Reference in gray system font with tracking

### 2. Book Picker (Sheet)

```
┌────────────────────────────────────┐
│ ← Books     Select Book        X   │
├────────────────────────────────────┤
│ [🔍 Search books...]               │
├────────────────────────────────────┤
│ OLD TESTAMENT                      │ ← Sticky
├────────────────────────────────────┤
│ • Genesis                  50 > │
│   Exodus                   40 > │
│   ...                            │
├────────────────────────────────────┤
│ NEW TESTAMENT                      │
├────────────────────────────────────┤
│   Matthew                  28 > │
│   ...                            │
└────────────────────────────────────┘
```

**Chapter Grid:**
```
┌────────────────────────────────────┐
│ ← Books         Genesis            │
├────────────────────────────────────┤
│                                    │
│   [1]  [2]  [3]  [4]  [5]         │
│   [6]  [7]  [8]  [9]  [10]        │
│   ...                              │
│                                    │
└────────────────────────────────────┘
```

Current chapter: Black fill, white text
Other chapters: Gray fill, black text

### 3. Paywall Card

```
┌────────────────────────────────────┐
│                                    │
│            [Crown Icon]            │
│                                    │
│    Unlock Scroll The Bible         │ ← Georgia font
│                                    │
│   Deeper study. Unlimited access.  │ ← Gray, tracked
│                                    │
│   ✓ AI-powered Bible study         │
│   ✓ Explain It Easier button       │
│   ✓ Cross-references & context     │
│   ✓ Ad-free experience             │
│                                    │
│   ┌─────────┬─────────┐            │
│   │ Pay Now │Free Trial│            │ ← Segmented toggle
│   └─────────┴─────────┘            │
│                                    │
│   ◉ Annual        Save 58%  $1.67  │
│   ○ Monthly                 $3.99  │
│                                    │
│   🛡 No commitment · Cancel...     │
│                                    │
│   ┌────────────────────┐           │
│   │     Continue       │           │ ← Black button
│   └────────────────────┘           │
│                                    │
│       Restore Purchases            │
│                                    │
│       Terms · Privacy              │
└────────────────────────────────────┘
```

### 4. AI Study View (Sheet)

```
┌────────────────────────────────────┐
│ Cancel                             │
├────────────────────────────────────┤
│           John 3:16                │
│    "For God so loved..."           │
├────────────────────────────────────┤
│   💡 Explain Easier             >  │
│   ─────────────────────────────    │
│   📖 Deeper Study               >  │
│   ─────────────────────────────    │
│   🔗 Related Verses             >  │
│                                    │
└────────────────────────────────────┘
```

Results view:
```
┌────────────────────────────────────┐
│ ← Back                             │
├────────────────────────────────────┤
│         💡 Explain Easier          │
│           John 3:16                │
├────────────────────────────────────┤
│                                    │
│   AI response text here...         │
│   With **bold** rendering          │
│                                    │
└────────────────────────────────────┘
```

### 5. Favorites View

```
┌────────────────────────────────────┐
│ Done        Saved Verses           │
├────────────────────────────────────┤
│                                    │
│   ┌────────────────────────────┐   │
│   │ "For God so loved..."      │   │
│   │                            │   │
│   │ John 3:16              ❤️  │   │
│   └────────────────────────────┘   │
│                                    │
│   ┌────────────────────────────┐   │
│   │ "I can do all things..."   │   │
│   │                            │   │
│   │ Philippians 4:13       ❤️  │   │
│   └────────────────────────────┘   │
│                                    │
└────────────────────────────────────┘
```

### 6. Notes Sheet

```
┌────────────────────────────────────┐
│                             Done   │
├────────────────────────────────────┤
│           John 3:16                │
│    "For God so loved..."           │
├────────────────────────────────────┤
│  Your Notes           Auto-saved   │
│  ┌────────────────────────────┐   │
│  │                            │   │
│  │ My personal reflection...  │   │
│  │                            │   │
│  └────────────────────────────┘   │
└────────────────────────────────────┘
```

### 7. Tutorial Flow

Scroll-based tutorial with:
- Each card fills screen (paging)
- Demo buttons that are interactive
- Paywall integrated
- Review request card
- Share request card
- Final exit trigger (blank white → fade to main)

---

## Responsive Design

### Height Breakpoints

```swift
let isCompact = geometry.size.height < 700
let isVeryCompact = geometry.size.height < 650
```

### Compact Adjustments

| Property | Normal | Compact | Very Compact |
|----------|--------|---------|--------------|
| Crown icon | 65-70pt | 55pt | 50pt |
| Title font | 26-28pt | 24pt | 22-24pt |
| Subtitle font | 14-15pt | 13pt | 12-13pt |
| Feature font | 15pt | 14pt | 13pt |
| Button font | 16-17pt | 15pt | 14-15pt |
| Vertical spacing | 24-40pt | 18-28pt | 16-20pt |
| Padding horizontal | 32-50pt | 28-40pt | 24-36pt |

### Dynamic Font Sizing for Verse Text

```swift
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
```

---

## SwiftUI Implementation Patterns

### 1. Force Light Mode

```swift
.preferredColorScheme(.light)
```

### 2. Paging Scroll

```swift
ScrollView(.vertical, showsIndicators: false) {
    LazyVStack(spacing: 0) {
        ForEach(items) { item in
            ItemView(item)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.paging)
```

### 3. Sheet Presentation

```swift
.sheet(isPresented: $showing) {
    ContentView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
```

### 4. Floating Header Pattern

```swift
ZStack {
    // Main content
    MainScrollView()
    
    // Floating header
    VStack {
        HeaderContent()
            .padding(.top, geo.safeAreaInsets.top + 6)
        Spacer()
    }
    .ignoresSafeArea(edges: .top)
}
```

### 5. Button Style (No Default Highlighting)

```swift
.buttonStyle(PlainButtonStyle())
```

### 6. Custom Press Animation

```swift
struct FastPopButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

### 7. Sticky Section Headers

```swift
LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
    Section {
        // Content
    } header: {
        SectionHeader("Title")
    }
}
```

### 8. Double-Tap Gesture with Location

```swift
.gesture(
    SpatialTapGesture(count: 2)
        .onEnded { event in
            handleDoubleTap(at: event.location)
        }
)
```

### 9. Coordinate Space for Position Tracking

```swift
.coordinateSpace(name: "MySpace")
.background(
    GeometryReader { geo in
        Color.clear.onAppear {
            let frame = geo.frame(in: .named("MySpace"))
            position = CGPoint(x: frame.midX, y: frame.midY)
        }
    }
)
```

### 10. Template Image Rendering

```swift
Image("icon-name")
    .renderingMode(.template)
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(width: 20, height: 20)
    .foregroundColor(.black)
```

---

## Key Animation Timings Reference

| Animation | Duration | Curve | Delay |
|-----------|----------|-------|-------|
| Button press | 0.1s | easeOut | - |
| Content fade in | 0.4s | easeIn | - |
| Post-tutorial fade | 2.5s | easeInOut | 0.1s |
| Element cascade | 0.4s | easeOut | +0.05-0.1s each |
| Spring bounce | 0.25-0.3s | spring | - |
| Toggle switch | 0.2s | easeInOut | - |
| Next chapter fade | 1.2-2.4s | easeInOut | 0.8s |
| Heart fly | 0.35s | easeIn | 0.3s |
| Crown spin | 1.2s | linear | repeat |

### Spring Configurations

```swift
// Fast snap back
.spring(response: 0.25, dampingFraction: 0.5)

// Bouncy
.spring(response: 0.3, dampingFraction: 0.4)

// Smooth settle
.spring(response: 0.4, dampingFraction: 0.7)

// Controlled
.spring(response: 0.5, dampingFraction: 0.7)
```

---

## Summary: The "Bible Scroll Look"

1. **Background**: Pure white everywhere
2. **Text**: Black for primary, gray for secondary
3. **Fonts**: Georgia for content, System for UI
4. **Buttons**: White circles/capsules with subtle shadows
5. **Animations**: Smooth, deliberate, cascading entrances
6. **Interactions**: Light haptics, quick scale animations
7. **Layout**: Full-screen paging, floating overlays
8. **Sheets**: Native iOS presentation with drag indicator
9. **Theme**: Forced light mode only
10. **Shadows**: Very subtle (0.08 opacity), always on Y axis

This creates a clean, modern, content-focused experience that feels premium and calm.




