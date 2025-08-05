import Foundation

struct Playlist: Identifiable, Codable {
    let id: UUID
    var name: String
    var songs: [Song]
    let createdDate: Date
    var lastModified: Date
    var isShuffled: Bool
    
    init(name: String, songs: [Song] = []) {
        self.id = UUID()
        self.name = name
        self.songs = songs
        self.createdDate = Date()
        self.lastModified = Date()
        self.isShuffled = false
    }
    
    // MARK: - Computed Properties
    var totalDuration: TimeInterval {
        return songs.reduce(0) { $0 + $1.duration }
    }
    
    var formattedDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var songCount: Int {
        return songs.count
    }
    
    // MARK: - Mutating Methods
    mutating func addSong(_ song: Song) {
        songs.append(song)
        lastModified = Date()
    }
    
    mutating func removeSong(at index: Int) {
        guard index < songs.count else { return }
        songs.remove(at: index)
        lastModified = Date()
    }
    
    mutating func moveSong(from source: IndexSet, to destination: Int) {
        songs.move(fromOffsets: source, toOffset: destination)
        lastModified = Date()
    }
    
    mutating func shuffle() {
        songs.shuffle()
        isShuffled = true
        lastModified = Date()
    }
    
    mutating func unshuffle() {
        // Note: This would require storing original order
        isShuffled = false
        lastModified = Date()
    }
}
