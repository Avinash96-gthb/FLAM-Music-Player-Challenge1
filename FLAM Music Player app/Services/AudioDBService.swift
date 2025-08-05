import Foundation
import Combine

class AudioDBService: MusicSourceProtocol {
    var sourceName: String = "AudioDB"
    var isAvailable: Bool = true
    
    private let baseURL = "https://www.theaudiodb.com/api/v1/json/2"
    private var cancellables = Set<AnyCancellable>()
    
    func initialize() -> AnyPublisher<Bool, Error> {
        return Future { promise in
            // Test API connectivity
            self.testAPIConnection()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            promise(.success(true))
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }
    
    func search(query: String) -> AnyPublisher<[Song], Error> {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/searchtrack.php?s=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: AudioDBError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AudioDBTrackResponse.self, decoder: JSONDecoder())
            .map { response in
                response.track?.compactMap { trackData in
                    self.convertAudioDBTrackToSong(trackData)
                } ?? []
            }
            .catch { error in
                Just([])
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func loadSong(song: Song) -> AnyPublisher<URL?, Error> {
        return Future { promise in
            // AudioDB doesn't provide actual audio files, only metadata
            // Return the preview URL if available
            promise(.success(song.previewURL))
        }
        .eraseToAnyPublisher()
    }
    
    func getRecommendations() -> AnyPublisher<[Song], Error> {
        // Get trending tracks or popular artists
        let urlString = "\(baseURL)/trending.php?country=us&type=itunes&format=singles"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: AudioDBError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AudioDBTrendingResponse.self, decoder: JSONDecoder())
            .map { response in
                response.trending?.compactMap { trackData in
                    self.convertTrendingDataToSong(trackData)
                } ?? []
            }
            .catch { error in
                // Return some hardcoded recommendations if API fails
                Just(self.getHardcodedRecommendations())
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func testAPIConnection() -> AnyPublisher<Bool, Error> {
        let testURL = "\(baseURL)/search.php?s=coldplay"
        
        guard let url = URL(string: testURL) else {
            return Fail(error: AudioDBError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { _ in true }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    private func convertAudioDBTrackToSong(_ trackData: AudioDBTrack) -> Song? {
        guard let title = trackData.strTrack,
              let artist = trackData.strArtist else {
            return nil
        }
        
        let duration = TimeInterval(trackData.intDuration ?? 0) / 1000 // Convert from milliseconds
        
        return Song(
            title: title,
            artist: artist,
            album: trackData.strAlbum,
            duration: duration,
            artworkURL: URL(string: trackData.strTrackThumb ?? ""),
            sourceType: .audioDB,
            sourceID: trackData.idTrack ?? UUID().uuidString,
            previewURL: URL(string: trackData.strMusicVid ?? "")
        )
    }
    
    private func convertTrendingDataToSong(_ trendingData: AudioDBTrending) -> Song? {
        guard let title = trendingData.strTrack,
              let artist = trendingData.strArtist else {
            return nil
        }
        
        return Song(
            title: title,
            artist: artist,
            album: trendingData.strAlbum,
            duration: TimeInterval(trendingData.intDuration ?? 180000) / 1000,
            artworkURL: URL(string: trendingData.strTrackThumb ?? ""),
            sourceType: .audioDB,
            sourceID: trendingData.idTrack ?? UUID().uuidString
        )
    }
    
    private func getHardcodedRecommendations() -> [Song] {
        return [
            Song(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera",
                duration: 355,
                sourceType: .audioDB,
                sourceID: "audiodb_32601"
            ),
            Song(
                title: "Hotel California",
                artist: "Eagles",
                album: "Hotel California",
                duration: 391,
                sourceType: .audioDB,
                sourceID: "audiodb_32602"
            ),
            Song(
                title: "Stairway to Heaven",
                artist: "Led Zeppelin",
                album: "Led Zeppelin IV",
                duration: 482,
                sourceType: .audioDB,
                sourceID: "audiodb_32603"
            ),
            Song(
                title: "Sweet Child O' Mine",
                artist: "Guns N' Roses",
                album: "Appetite for Destruction",
                duration: 356,
                sourceType: .audioDB,
                sourceID: "audiodb_32604"
            ),
            Song(
                title: "Imagine",
                artist: "John Lennon",
                album: "Imagine",
                duration: 183,
                sourceType: .audioDB,
                sourceID: "audiodb_32605"
            )
        ]
    }
}

// MARK: - AudioDB Data Models

struct AudioDBTrackResponse: Codable {
    let track: [AudioDBTrack]?
}

struct AudioDBTrack: Codable {
    let idTrack: String?
    let strTrack: String?
    let strArtist: String?
    let strAlbum: String?
    let intDuration: Int?
    let strTrackThumb: String?
    let strMusicVid: String?
}

struct AudioDBTrendingResponse: Codable {
    let trending: [AudioDBTrending]?
}

struct AudioDBTrending: Codable {
    let idTrack: String?
    let strTrack: String?
    let strArtist: String?
    let strAlbum: String?
    let intDuration: Int?
    let strTrackThumb: String?
}

// MARK: - AudioDB Errors
enum AudioDBError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid AudioDB URL"
        case .noData:
            return "No data received from AudioDB"
        case .decodingError:
            return "Failed to decode AudioDB response"
        case .networkError(let message):
            return "AudioDB network error: \(message)"
        }
    }
}
