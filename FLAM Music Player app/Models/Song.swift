import Foundation

struct Song: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let artist: String
    let album: String?
    let duration: TimeInterval
    let artworkURL: URL?
    let sourceType: MusicSourceType
    let sourceID: String // ID specific to the source (file path, Spotify ID, etc.)
    let previewURL: URL? // For streaming previews
    
    init(
        title: String,
        artist: String,
        album: String? = nil,
        duration: TimeInterval,
        artworkURL: URL? = nil,
        sourceType: MusicSourceType,
        sourceID: String,
        previewURL: URL? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artworkURL = artworkURL
        self.sourceType = sourceType
        self.sourceID = sourceID
        self.previewURL = previewURL
    }
    
    // MARK: - Computed Properties
    var displayName: String {
        return "\(title) - \(artist)"
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Music Source Types
enum MusicSourceType: String, CaseIterable, Codable {
    case local = "Local Files"
    case spotify = "Spotify"
    case audioDB = "AudioDB"
    
    var iconName: String {
        switch self {
        case .local:
            return "music.note"
        case .spotify:
            return "music.note.tv"
        case .audioDB:
            return "globe"
        }
    }
}
