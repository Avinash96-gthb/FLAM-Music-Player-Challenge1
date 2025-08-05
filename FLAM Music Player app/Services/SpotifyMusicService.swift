import Foundation
import Combine

class SpotifyMusicService: MusicSourceProtocol {
    var sourceName: String = "Spotify"
    var isAvailable: Bool = false // Mock service - not actually available
    
    private var mockSpotifySongs: [Song] = []
    
    func initialize() -> AnyPublisher<Bool, Error> {
        return Future { promise in
            DispatchQueue.global().async {
                // Simulate API initialization delay
                Thread.sleep(forTimeInterval: 1.0)
                
                self.loadMockSpotifyData()
                self.isAvailable = true
                
                DispatchQueue.main.async {
                    promise(.success(true))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func search(query: String) -> AnyPublisher<[Song], Error> {
        return Future { promise in
            // Simulate network delay
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                let filteredSongs = self.mockSpotifySongs.filter { song in
                    song.title.localizedCaseInsensitiveContains(query) ||
                    song.artist.localizedCaseInsensitiveContains(query) ||
                    song.album?.localizedCaseInsensitiveContains(query) == true
                }
                
                DispatchQueue.main.async {
                    promise(.success(filteredSongs))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func loadSong(song: Song) -> AnyPublisher<URL?, Error> {
        return Future { promise in
            // Simulate loading a preview URL (30 seconds)
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                // In a real implementation, this would return the actual stream URL
                // For demo purposes, we'll return the preview URL if available
                DispatchQueue.main.async {
                    promise(.success(song.previewURL))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getRecommendations() -> AnyPublisher<[Song], Error> {
        return Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                // Return trending/popular songs
                let recommendations = Array(self.mockSpotifySongs.shuffled().prefix(15))
                
                DispatchQueue.main.async {
                    promise(.success(recommendations))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func loadMockSpotifyData() {
        mockSpotifySongs = [
            Song(
                title: "Blinding Lights",
                artist: "The Weeknd",
                album: "After Hours",
                duration: 200,
                artworkURL: URL(string: "https://example.com/artwork1.jpg"),
                sourceType: .spotify,
                sourceID: "spotify:track:0VjIjW4GlULA",
                previewURL: URL(string: "https://example.com/preview1.mp3")
            ),
            Song(
                title: "Watermelon Sugar",
                artist: "Harry Styles",
                album: "Fine Line",
                duration: 174,
                artworkURL: URL(string: "https://example.com/artwork2.jpg"),
                sourceType: .spotify,
                sourceID: "spotify:track:6UelLqGlWMcG",
                previewURL: URL(string: "https://example.com/preview2.mp3")
            ),
            Song(
                title: "Good 4 U",
                artist: "Olivia Rodrigo",
                album: "SOUR",
                duration: 178,
                artworkURL: URL(string: "https://example.com/artwork3.jpg"),
                sourceType: .spotify,
                sourceID: "spotify:track:4ZtFanR9U6n",
                previewURL: URL(string: "https://example.com/preview3.mp3")
            ),
            Song(
                title: "Levitating",
                artist: "Dua Lipa",
                album: "Future Nostalgia",
                duration: 203,
                artworkURL: URL(string: "https://example.com/artwork4.jpg"),
                sourceType: .spotify,
                sourceID: "spotify:track:463CkQjx2Z",
                previewURL: URL(string: "https://example.com/preview4.mp3")
            ),
            Song(
                title: "Stay",
                artist: "The Kid LAROI, Justin Bieber",
                album: "Stay",
                duration: 141,
                artworkURL: URL(string: "https://example.com/artwork5.jpg"),
                sourceType: .spotify,
                sourceID: "spotify:track:5HCyWlXZPP0",
                previewURL: URL(string: "https://example.com/preview5.mp3")
            ),
            Song(
                title: "Heat Waves",
                artist: "Glass Animals",
                album: "Dreamland",
                duration: 238,
                artworkURL: URL(string: "https://example.com/artwork6.jpg"),
                sourceType: .spotify,
                sourceID: "spotify:track:02MWAaffLxlfxAU",
                previewURL: URL(string: "https://example.com/preview6.mp3")
            ),
            Song(
                title: "Anti-Hero",
                artist: "Taylor Swift",
                album: "Midnights",
                duration: 200,
                artworkURL: URL(string: "https://example.com/artwork7.jpg"),
                sourceType: .spotify,
                sourceID: "spotify:track:0V3wPSX9ygBn",
                previewURL: URL(string: "https://example.com/preview7.mp3")
            ),
            Song(
                title: "As It Was",
                artist: "Harry Styles",
                album: "Harry's House",
                duration: 167,
                artworkURL: URL(string: "https://example.com/artwork8.jpg"),
                sourceType: .spotify,
                sourceID: "spotify:track:4Dvkj6JhhA",
                previewURL: URL(string: "https://example.com/preview8.mp3")
            )
        ]
    }
}
