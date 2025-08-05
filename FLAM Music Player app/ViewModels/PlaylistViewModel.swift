import Foundation
import Combine

class PlaylistViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var currentPlaylist: Playlist?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let musicPlayerService = MusicPlayerService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSamplePlaylists()
    }
    
    // MARK: - Playlist Management
    
    func createPlaylist(name: String) {
        let newPlaylist = Playlist(name: name)
        playlists.append(newPlaylist)
        savePlaylistsToUserDefaults()
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        if currentPlaylist?.id == playlist.id {
            currentPlaylist = nil
        }
        savePlaylistsToUserDefaults()
    }
    
    func renamePlaylist(_ playlist: Playlist, to newName: String) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].name = newName
            playlists[index].lastModified = Date()
            
            if currentPlaylist?.id == playlist.id {
                currentPlaylist = playlists[index]
            }
            
            savePlaylistsToUserDefaults()
        }
    }
    
    func selectPlaylist(_ playlist: Playlist) {
        currentPlaylist = playlist
    }
    
    // MARK: - Song Management
    
    func addSongToPlaylist(_ song: Song, playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].addSong(song)
            
            if currentPlaylist?.id == playlist.id {
                currentPlaylist = playlists[index]
            }
            
            savePlaylistsToUserDefaults()
        }
    }
    
    func removeSongFromPlaylist(at songIndex: Int, from playlist: Playlist) {
        if let playlistIndex = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[playlistIndex].removeSong(at: songIndex)
            
            if currentPlaylist?.id == playlist.id {
                currentPlaylist = playlists[playlistIndex]
            }
            
            savePlaylistsToUserDefaults()
        }
    }
    
    func moveSongInPlaylist(from source: IndexSet, to destination: Int, in playlist: Playlist) {
        if let playlistIndex = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[playlistIndex].moveSong(from: source, to: destination)
            
            if currentPlaylist?.id == playlist.id {
                currentPlaylist = playlists[playlistIndex]
            }
            
            savePlaylistsToUserDefaults()
        }
    }
    
    // MARK: - Playback Integration
    
    func playPlaylist(_ playlist: Playlist, startAt index: Int = 0) {
        guard !playlist.songs.isEmpty else { return }
        
        musicPlayerService.setQueue(playlist.songs, startIndex: index)
        selectPlaylist(playlist)
    }
    
    func shufflePlaylist(_ playlist: Playlist) {
        guard !playlist.songs.isEmpty else { return }
        
        var shuffledSongs = playlist.songs
        shuffledSongs.shuffle()
        
        musicPlayerService.setQueue(shuffledSongs, startIndex: 0)
        selectPlaylist(playlist)
    }
    
    func addPlaylistToQueue(_ playlist: Playlist) {
        for song in playlist.songs {
            musicPlayerService.addToQueue(song)
        }
    }
    
    // MARK: - Search and Filter
    
    func searchPlaylistsContaining(song: Song) -> [Playlist] {
        return playlists.filter { playlist in
            playlist.songs.contains { $0.id == song.id }
        }
    }
    
    func filterPlaylists(by searchText: String) -> [Playlist] {
        guard !searchText.isEmpty else { return playlists }
        
        return playlists.filter { playlist in
            playlist.name.localizedCaseInsensitiveContains(searchText) ||
            playlist.songs.contains { song in
                song.title.localizedCaseInsensitiveContains(searchText) ||
                song.artist.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Statistics
    
    var totalPlaylists: Int {
        return playlists.count
    }
    
    var totalSongs: Int {
        return playlists.reduce(0) { $0 + $1.songCount }
    }
    
    var totalDuration: TimeInterval {
        return playlists.reduce(0) { $0 + $1.totalDuration }
    }
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Persistence
    
    private func savePlaylistsToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(playlists)
            UserDefaults.standard.set(data, forKey: "SavedPlaylists")
        } catch {
            errorMessage = "Failed to save playlists: \(error.localizedDescription)"
        }
    }
    
    private func loadPlaylistsFromUserDefaults() {
        guard let data = UserDefaults.standard.data(forKey: "SavedPlaylists") else {
            return
        }
        
        do {
            playlists = try JSONDecoder().decode([Playlist].self, from: data)
        } catch {
            errorMessage = "Failed to load playlists: \(error.localizedDescription)"
            loadSamplePlaylists()
        }
    }
    
    private func loadSamplePlaylists() {
        let sampleSongs = createSampleSongs()
        
        let rockPlaylist = Playlist(name: "Rock Classics", songs: Array(sampleSongs.prefix(5)))
        let popPlaylist = Playlist(name: "Pop Hits", songs: Array(sampleSongs.dropFirst(5).prefix(3)))
        let favoritesPlaylist = Playlist(name: "My Favorites", songs: [sampleSongs[0], sampleSongs[3], sampleSongs[6]])
        
        playlists = [rockPlaylist, popPlaylist, favoritesPlaylist]
    }
    
    private func createSampleSongs() -> [Song] {
        return [
            Song(title: "Bohemian Rhapsody", artist: "Queen", album: "A Night at the Opera", duration: 355, sourceType: .local, sourceID: "local_1"),
            Song(title: "Hotel California", artist: "Eagles", album: "Hotel California", duration: 391, sourceType: .local, sourceID: "local_2"),
            Song(title: "Stairway to Heaven", artist: "Led Zeppelin", album: "Led Zeppelin IV", duration: 482, sourceType: .local, sourceID: "local_3"),
            Song(title: "Sweet Child O' Mine", artist: "Guns N' Roses", album: "Appetite for Destruction", duration: 356, sourceType: .local, sourceID: "local_4"),
            Song(title: "Back in Black", artist: "AC/DC", album: "Back in Black", duration: 255, sourceType: .local, sourceID: "local_5"),
            Song(title: "Billie Jean", artist: "Michael Jackson", album: "Thriller", duration: 294, sourceType: .local, sourceID: "local_6"),
            Song(title: "Like a Rolling Stone", artist: "Bob Dylan", album: "Highway 61 Revisited", duration: 369, sourceType: .local, sourceID: "local_7"),
            Song(title: "Imagine", artist: "John Lennon", album: "Imagine", duration: 183, sourceType: .local, sourceID: "local_8")
        ]
    }
}

// MARK: - Convenience Methods
extension PlaylistViewModel {
    func createPlaylistWithSongs(name: String, songs: [Song]) {
        var newPlaylist = Playlist(name: name)
        newPlaylist.songs = songs
        playlists.append(newPlaylist)
        savePlaylistsToUserDefaults()
    }
    
    func duplicatePlaylist(_ playlist: Playlist) {
        let duplicatedPlaylist = Playlist(name: "\(playlist.name) Copy", songs: playlist.songs)
        playlists.append(duplicatedPlaylist)
        savePlaylistsToUserDefaults()
    }
    
    func getPlaylistDuration(_ playlist: Playlist) -> String {
        return playlist.formattedDuration
    }
    
    func getPlaylistSongCount(_ playlist: Playlist) -> String {
        let count = playlist.songCount
        return count == 1 ? "1 song" : "\(count) songs"
    }
}
