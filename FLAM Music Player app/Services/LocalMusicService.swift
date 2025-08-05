import Foundation
import Combine
import AVFoundation

class LocalMusicService: MusicSourceProtocol {
    var sourceName: String = "Local Files"
    var isAvailable: Bool = true
    
    private var localSongs: [Song] = []
    
    func initialize() -> AnyPublisher<Bool, Error> {
        return Future { promise in
            DispatchQueue.global().async {
                self.loadLocalMusicLibrary()
                DispatchQueue.main.async {
                    promise(.success(true))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func search(query: String) -> AnyPublisher<[Song], Error> {
        return Future { promise in
            let filteredSongs = self.localSongs.filter { song in
                song.title.localizedCaseInsensitiveContains(query) ||
                song.artist.localizedCaseInsensitiveContains(query) ||
                song.album?.localizedCaseInsensitiveContains(query) == true
            }
            promise(.success(filteredSongs))
        }
        .eraseToAnyPublisher()
    }
    
    func loadSong(song: Song) -> AnyPublisher<URL?, Error> {
        return Future { promise in
            // For local files, the sourceID contains the file path
            let url = URL(fileURLWithPath: song.sourceID)
            
            if FileManager.default.fileExists(atPath: song.sourceID) {
                promise(.success(url))
            } else {
                promise(.failure(LocalMusicError.fileNotFound))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getRecommendations() -> AnyPublisher<[Song], Error> {
        return Future { promise in
            // Return a random selection of local songs as recommendations
            let shuffled = self.localSongs.shuffled()
            let recommendations = Array(shuffled.prefix(10))
            promise(.success(recommendations))
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func loadLocalMusicLibrary() {
        // Load from Documents directory and bundle
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let bundlePath = Bundle.main.bundleURL
        
        var songs: [Song] = []
        
        // Load from documents directory
        songs.append(contentsOf: loadSongsFromDirectory(documentsPath))
        
        // Load from app bundle
        songs.append(contentsOf: loadSongsFromDirectory(bundlePath))
        
        // Add some sample songs for demo purposes
        songs.append(contentsOf: createSampleLocalSongs())
        
        self.localSongs = songs
    }
    
    private func loadSongsFromDirectory(_ directory: URL) -> [Song] {
        var songs: [Song] = []
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            )
            
            let audioFiles = fileURLs.filter { url in
                let supportedExtensions = ["mp3", "m4a", "wav", "aac", "flac"]
                return supportedExtensions.contains(url.pathExtension.lowercased())
            }
            
            for fileURL in audioFiles {
                if let song = createSongFromFile(fileURL) {
                    songs.append(song)
                }
            }
            
        } catch {
            print("Error loading local music directory: \(error)")
        }
        
        return songs
    }
    
    private func createSongFromFile(_ fileURL: URL) -> Song? {
        let asset = AVAsset(url: fileURL)
        var title = fileURL.deletingPathExtension().lastPathComponent
        var artist = "Unknown Artist"
        var album: String?
        var duration: TimeInterval = 0
        
        // Extract metadata
        let metadataItems = asset.commonMetadata
        for item in metadataItems {
            guard let key = item.commonKey?.rawValue,
                  let value = item.stringValue else { continue }
            
            switch key {
            case "title":
                title = value
            case "artist":
                artist = value
            case "albumName":
                album = value
            default:
                break
            }
        }
        
        // Get duration
        duration = CMTimeGetSeconds(asset.duration)
        if duration.isNaN || duration.isInfinite {
            duration = 0
        }
        
        return Song(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            artworkURL: nil,
            sourceType: .local,
            sourceID: fileURL.path
        )
    }
    
    private func createSampleLocalSongs() -> [Song] {
        return [
            Song(
                title: "Sample Song 1",
                artist: "Local Artist",
                album: "Demo Album",
                duration: 180,
                sourceType: .local,
                sourceID: "/path/to/sample1.mp3"
            ),
            Song(
                title: "Sample Song 2",
                artist: "Another Artist",
                album: "Demo Album",
                duration: 210,
                sourceType: .local,
                sourceID: "/path/to/sample2.mp3"
            ),
            Song(
                title: "Local Track",
                artist: "Indie Artist",
                album: "Self Released",
                duration: 195,
                sourceType: .local,
                sourceID: "/path/to/local_track.mp3"
            )
        ]
    }
}

// MARK: - Local Music Errors
enum LocalMusicError: LocalizedError {
    case fileNotFound
    case invalidFormat
    case metadataError
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Audio file not found"
        case .invalidFormat:
            return "Unsupported audio format"
        case .metadataError:
            return "Could not read file metadata"
        }
    }
}
