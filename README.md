# Bible Scroll

A minimalist iOS app for reading the Bible with TikTok-style vertical scrolling. Swipe through verses one at a time in a clean, distraction-free interface.

## Features

- **TikTok-style scrolling**: Swipe vertically to navigate verse by verse
- **Minimalist design**: Pure white background with clean black text
- **Save favorites**: Tap the heart icon to save verses for later
- **Personal notes**: Add your own notes to any verse
- **Share verses**: Easily share verses with friends and family
- **Book/Chapter picker**: Navigate to any book and chapter in the Bible

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Open `BibleScroll.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on your device or simulator

## Configuring API.Bible

The app is configured to use [API.Bible](https://scripture.api.bible). To set up:

1. Open `BibleScroll/Services/APIConfig.swift`
2. Replace the API key with your full key from API.Bible dashboard
3. Optionally change the `bibleId` to use a different translation

```swift
// In APIConfig.swift
static let apiBibleKey = "YOUR_FULL_API_KEY_HERE"

// Change Bible version (optional)
static let bibleId = "de4e12af7f28f599-02"  // KJV (default)
```

### Available Bible Versions

| Bible ID | Version |
|----------|---------|
| `de4e12af7f28f599-02` | KJV (King James Version) |
| `06125adad2d5898a-01` | ASV (American Standard Version) |
| `9879dbb7cfe39e4d-04` | WEB (World English Bible) |

Find more versions at: https://scripture.api.bible/livedocs#/Bibles/getBibles

### API Usage

- The app fetches one chapter at a time (1 API call per chapter)
- With Pro plan (150K calls/month), you have plenty of headroom
- Fallback sample data is used if the API is unavailable

## Project Structure

```
BibleScroll/
├── App/
│   ├── BibleScrollApp.swift      # App entry point with SwiftData setup
│   └── ContentView.swift         # Main container view
├── Models/
│   ├── Verse.swift               # Verse data model
│   ├── Book.swift                # Book/chapter structure
│   ├── Favorite.swift            # SwiftData model for saved verses
│   └── Note.swift                # SwiftData model for notes
├── Views/
│   ├── MainScrollView.swift      # TikTok-style vertical paging
│   ├── VerseCardView.swift       # Individual verse display
│   ├── ActionButtonsView.swift   # Like, note, share buttons
│   ├── BookPickerView.swift      # Book/chapter selection
│   ├── NotesSheetView.swift      # Personal notes input
│   └── FavoritesView.swift       # Saved verses list
├── ViewModels/
│   ├── BibleViewModel.swift      # Main data orchestration
│   └── FavoritesViewModel.swift  # Favorites management
├── Services/
│   ├── BibleAPIService.swift     # REST API client
│   ├── StorageService.swift      # SwiftData operations
│   └── AuthService.swift         # Optional auth (placeholder)
└── Utilities/
    └── Extensions.swift          # Helper extensions
```

## Tech Stack

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Apple's latest persistence framework
- **MVVM Architecture**: Clean separation of concerns
- **async/await**: Modern Swift concurrency

## Customization

### Changing the font
In `VerseCardView.swift`, modify the font:

```swift
Text(verse.text)
    .font(.custom("YourFontName", size: 24))
```

### Adjusting the theme
The app uses a pure white background. To modify colors, update the `Color.white` references in the view files.

### Adding Bible translations
Extend the `BibleAPIService` to support multiple translations by adding a translation parameter to the API calls.

## License

This project is for personal/educational use.

