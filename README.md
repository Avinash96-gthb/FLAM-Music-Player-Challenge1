# FLAM Music Player App

A comprehensive iOS music player application built with SwiftUI and Combine, demonstrating various design patterns and best practices in iOS development.

## Architecture Overview

This application follows the **MVVM (Model-View-ViewModel)** architecture pattern combined with **Combine** for reactive programming and implements several design patterns including:

- **Strategy Pattern** - For different music sources
- **Singleton Pattern** - For the music player service
- **Observer Pattern** - For state notifications
- **Factory Pattern** - For creating music sources

## Key Features

### 🎵 Multiple Music Sources
- **Local Files**: Play music files stored on the device
- **Spotify Integration**: Mock implementation of Spotify streaming
- **AudioDB Service**: Discover music from TheAudioDB online database

### 🎮 Comprehensive Playback Control
- Play, pause, stop, skip, previous functionality
- Seek functionality with progress tracking
- Volume control
- Repeat modes (None, One, All)
- Shuffle functionality

### 📱 Rich User Interface
- **Player View**: Beautiful player interface with controls
- **Source Selection**: Browse and search different music sources
- **Playlist Management**: Create, edit, and manage playlists
- **Queue Management**: Dynamic queue with reordering capabilities

### 🔄 Reactive Architecture
- Real-time state updates using Combine
- Responsive UI updates
- Efficient data binding between ViewModels and Views

## Project Structure

```
FLAM Music Player app/
├── Models/                     # Data models
│   ├── Song.swift             # Song entity with metadata
│   ├── Playlist.swift         # Playlist management
│   ├── PlayerState.swift      # Player state definitions
│   └── MusicSource.swift      # Music source types
├── ViewModels/                # MVVM ViewModels
│   ├── MusicPlayerViewModel.swift    # Main player logic
│   ├── PlaylistViewModel.swift       # Playlist management
│   └── SourceSelectionViewModel.swift # Source selection logic
├── Views/                     # SwiftUI Views
│   ├── PlayerView.swift       # Main player interface
│   ├── PlaylistView.swift     # Playlist management UI
│   └── SourceSelectionView.swift # Source browsing UI
├── Services/                  # Business logic services
│   ├── MusicPlayerService.swift     # Core player service (Singleton)
│   ├── LocalMusicService.swift      # Local file handling
│   ├── SpotifyMusicService.swift    # Spotify integration (Mock)
│   └── AudioDBService.swift         # AudioDB API integration
├── Protocols/                 # Interface definitions
│   ├── MusicSourceProtocol.swift    # Strategy pattern interface
│   └── PlayerNotificationProtocol.swift # Observer pattern interface
├── Managers/                  # Specialized managers
│   ├── PlaybackManager.swift        # Audio playback handling
│   └── QueueManager.swift           # Queue management logic
└── Utils/                     # Utilities and extensions
    ├── Constants.swift               # App constants
    └── Extensions.swift              # Useful extensions
```

## Design Patterns Implementation

### 1. Strategy Pattern
The `MusicSourceProtocol` defines a common interface for different music sources:

```swift
protocol MusicSourceProtocol {
    var sourceName: String { get }
    var isAvailable: Bool { get }
    
    func initialize() -> AnyPublisher<Bool, Error>
    func search(query: String) -> AnyPublisher<[Song], Error>
    func loadSong(song: Song) -> AnyPublisher<URL?, Error>
    func getRecommendations() -> AnyPublisher<[Song], Error>
}
```

**Implementations:**
- `LocalMusicService` - Handles local audio files
- `SpotifyMusicService` - Mock Spotify integration
- `AudioDBService` - TheAudioDB API integration

### 2. Singleton Pattern
`MusicPlayerService` ensures only one instance of the player exists:

```swift
class MusicPlayerService: ObservableObject {
    static let shared = MusicPlayerService()
    private init() { /* initialization */ }
}
```

### 3. Observer Pattern
The `PlayerNotificationProtocol` allows multiple observers to receive player updates:

```swift
protocol PlayerNotificationProtocol {
    func playerStateDidChange(_ state: PlayerState)
    func playbackProgressDidUpdate(_ progress: PlaybackProgress)
    func queueDidUpdate(_ queue: [Song])
    func currentSongDidChange(_ song: Song?)
}
```

### 4. MVVM Architecture
- **Models**: Pure data structures (`Song`, `Playlist`, `PlayerState`)
- **ViewModels**: Business logic and state management
- **Views**: SwiftUI views that bind to ViewModels

## Key Components

### MusicPlayerService (Singleton)
The core service that manages:
- Audio playback using AVAudioPlayer
- Queue management
- State notifications
- Music source coordination

### Music Sources (Strategy Pattern)
- **LocalMusicService**: Scans device for audio files
- **SpotifyMusicService**: Mock implementation with sample data
- **AudioDBService**: Real API integration with TheAudioDB

### ViewModels
- **MusicPlayerViewModel**: Main player state and controls
- **PlaylistViewModel**: Playlist management and persistence
- **SourceSelectionViewModel**: Source selection and search

### Views
- **PlayerView**: Main player interface with controls and artwork
- **PlaylistView**: Playlist management with create, edit, delete
- **SourceSelectionView**: Source browsing and search interface

## Getting Started

### Prerequisites
- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

### Installation
1. Clone the repository
2. Open `FLAM Music Player app.xcodeproj` in Xcode
3. Build and run the project

### Configuration
The app works out of the box with:
- Local file support (place audio files in Documents directory)
- AudioDB integration (requires internet connection)
- Mock Spotify data for demonstration

## API Integration

### AudioDB Integration
The app integrates with [TheAudioDB](https://www.theaudiodb.com/) for music discovery:
- Search for tracks by artist, song, or album
- Get trending music data
- Fetch music metadata

### Usage Example
```swift
let audioDBService = AudioDBService()
audioDBService.search(query: "coldplay")
    .sink(receiveValue: { songs in
        // Handle search results
    })
```

## State Management

The app uses Combine for reactive state management:

```swift
@Published var currentSong: Song?
@Published var playerState: PlayerState = .idle
@Published var playbackProgress: PlaybackProgress
```

Views automatically update when state changes through `@StateObject` and `@ObservedObject`.

## Data Persistence

- **Playlists**: Stored in UserDefaults using JSON encoding
- **User Preferences**: Managed through UserDefaults
- **Recent Searches**: Cached for quick access

## Error Handling

Comprehensive error handling throughout:
- Network errors for API calls
- File system errors for local music
- Audio playback errors
- User-friendly error messages

## Testing Strategy

The architecture supports easy testing:
- **Unit Tests**: Test ViewModels and Services independently
- **Integration Tests**: Test music source implementations
- **UI Tests**: Test SwiftUI views and user interactions

## Future Enhancements

- [ ] Real Spotify SDK integration
- [ ] Cloud storage support (iCloud, Dropbox)
- [ ] Equalizer and audio effects
- [ ] Social features (sharing playlists)
- [ ] Offline mode for streaming sources
- [ ] CarPlay support
- [ ] Watch app companion

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement your changes following the existing patterns
4. Add appropriate tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [TheAudioDB](https://www.theaudiodb.com/) for providing free music metadata API
- Apple's AVFoundation framework for audio playback
- SwiftUI and Combine for reactive UI development
