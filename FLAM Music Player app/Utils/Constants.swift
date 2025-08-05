import Foundation

// MARK: - App Constants
struct Constants {
    
    // MARK: - Audio Settings
    struct Audio {
        static let defaultVolume: Float = 0.7
        static let fadeInDuration: TimeInterval = 0.5
        static let fadeOutDuration: TimeInterval = 0.3
        static let progressUpdateInterval: TimeInterval = 0.1
    }
    
    // MARK: - UI Constants
    struct UI {
        static let artworkSize: CGFloat = 50
        static let largeArtworkSize: CGFloat = 200
        static let cornerRadius: CGFloat = 8
        static let animationDuration: Double = 0.3
        static let maxSearchResults: Int = 50
    }
    
    // MARK: - API Constants
    struct API {
        static let audioDBBaseURL = "https://www.theaudiodb.com/api/v1/json/2"
        static let requestTimeout: TimeInterval = 30
        static let maxRetryAttempts = 3
    }
    
    // MARK: - Storage Keys
    struct StorageKeys {
        static let savedPlaylists = "SavedPlaylists"
        static let lastSelectedSource = "LastSelectedSource"
        static let userPreferences = "UserPreferences"
        static let recentSearches = "RecentSearches"
    }
    
    // MARK: - File Extensions
    struct FileExtensions {
        static let supportedAudioFormats = ["mp3", "m4a", "wav", "aac", "flac", "aiff"]
        static let playlistFormats = ["m3u", "m3u8", "pls"]
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var volume: Float = Constants.Audio.defaultVolume
    var repeatMode: RepeatMode = .none
    var preferredMusicSource: MusicSourceType = .local
    var showArtwork: Bool = true
    var enableCrossfade: Bool = false
    var maxSearchHistory: Int = 20
    
    // Load from UserDefaults
    static func load() -> UserPreferences {
        guard let data = UserDefaults.standard.data(forKey: Constants.StorageKeys.userPreferences),
              let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return UserPreferences()
        }
        return preferences
    }
    
    // Save to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Constants.StorageKeys.userPreferences)
        }
    }
}
