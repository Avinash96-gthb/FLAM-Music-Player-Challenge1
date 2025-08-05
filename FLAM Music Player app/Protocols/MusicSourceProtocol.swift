import Foundation
import Combine

// MARK: - Strategy Pattern Protocol
protocol MusicSourceProtocol {
    var sourceName: String { get }
    var isAvailable: Bool { get }
    
    func initialize() -> AnyPublisher<Bool, Error>
    func search(query: String) -> AnyPublisher<[Song], Error>
    func loadSong(song: Song) -> AnyPublisher<URL?, Error>
    func getRecommendations() -> AnyPublisher<[Song], Error>
}
