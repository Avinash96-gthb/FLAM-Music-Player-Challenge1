import Foundation
import Combine

class MusicPlayerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSong: Song?
    @Published var playerState: PlayerState = .idle
    @Published var playbackProgress: PlaybackProgress = PlaybackProgress(currentTime: 0, duration: 0)
    @Published var isPlaying: Bool = false
    @Published var volume: Float = 1.0
    @Published var repeatMode: RepeatMode = .none
    @Published var isShuffled: Bool = false
    @Published var queue: [Song] = []
    @Published var currentMusicSource: MusicSourceType = .local
    @Published var availableSources: [MusicSource] = []
    
    // MARK: - Private Properties
    let musicPlayerService = MusicPlayerService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        initializeAvailableSources()
    }
    
    // MARK: - Public Methods
    
    // MARK: - Playback Control
    func play() {
        musicPlayerService.play()
    }
    
    func pause() {
        musicPlayerService.pause()
    }
    
    func stop() {
        musicPlayerService.stop()
    }
    
    func skipToNext() {
        musicPlayerService.skip()
    }
    
    func skipToPrevious() {
        musicPlayerService.previous()
    }
    
    func seek(to time: TimeInterval) {
        musicPlayerService.seek(to: time)
    }
    
    func setVolume(_ volume: Float) {
        self.volume = volume
        musicPlayerService.volume = volume
    }
    
    // MARK: - Queue Management
    func setQueue(_ songs: [Song], startAt index: Int = 0) {
        musicPlayerService.setQueue(songs, startIndex: index)
    }
    
    func addToQueue(_ song: Song) {
        musicPlayerService.addToQueue(song)
    }
    
    func removeFromQueue(at index: Int) {
        musicPlayerService.removeFromQueue(at: index)
    }
    
    func clearQueue() {
        musicPlayerService.clearQueue()
    }
    
    // MARK: - Shuffle & Repeat
    func toggleShuffle() {
        if isShuffled {
            // Unshuffle logic would go here
            isShuffled = false
        } else {
            musicPlayerService.shuffleQueue()
            isShuffled = true
        }
    }
    
    func toggleRepeat() {
        switch repeatMode {
        case .none:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .none
        }
        musicPlayerService.repeatMode = repeatMode
    }
    
    // MARK: - Source Management
    func changeMusicSource(to sourceType: MusicSourceType) {
        currentMusicSource = sourceType
        musicPlayerService.setMusicSource(sourceType)
        
        // Clear current queue when switching sources
        clearQueue()
    }
    
    func searchMusic(query: String) -> AnyPublisher<[Song], Error> {
        return musicPlayerService.searchSongs(query: query)
    }
    
    // MARK: - Computed Properties
    var formattedCurrentTime: String {
        return playbackProgress.formattedCurrentTime
    }
    
    var formattedDuration: String {
        return playbackProgress.formattedDuration
    }
    
    var progressPercentage: Double {
        return playbackProgress.progress
    }
    
    var canPlayPrevious: Bool {
        return musicPlayerService.currentIndex > 0 || repeatMode == .all
    }
    
    var canPlayNext: Bool {
        return musicPlayerService.currentIndex < queue.count - 1 || repeatMode == .all
    }
    
    var queuePosition: String {
        guard !queue.isEmpty else { return "0 / 0" }
        return "\(musicPlayerService.currentIndex + 1) / \(queue.count)"
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind to MusicPlayerService published properties
        musicPlayerService.$currentSong
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentSong, on: self)
            .store(in: &cancellables)
        
        musicPlayerService.$playerState
            .receive(on: DispatchQueue.main)
            .assign(to: \.playerState, on: self)
            .store(in: &cancellables)
        
        musicPlayerService.$playbackProgress
            .receive(on: DispatchQueue.main)
            .assign(to: \.playbackProgress, on: self)
            .store(in: &cancellables)
        
        musicPlayerService.$queue
            .receive(on: DispatchQueue.main)
            .assign(to: \.queue, on: self)
            .store(in: &cancellables)
        
        musicPlayerService.$repeatMode
            .receive(on: DispatchQueue.main)
            .assign(to: \.repeatMode, on: self)
            .store(in: &cancellables)
        
        musicPlayerService.$isShuffled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isShuffled, on: self)
            .store(in: &cancellables)
        
        musicPlayerService.$volume
            .receive(on: DispatchQueue.main)
            .assign(to: \.volume, on: self)
            .store(in: &cancellables)
        
        // Derive isPlaying from playerState
        musicPlayerService.$playerState
            .map { $0.isPlaying }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)
    }
    
    private func initializeAvailableSources() {
        availableSources = [
            MusicSource(type: .local, isAvailable: true, description: "Local music files"),
            MusicSource(type: .spotify, isAvailable: false, description: "Spotify streaming (Mock)"),
            MusicSource(type: .audioDB, isAvailable: true, description: "AudioDB online database")
        ]
        
        // Set default source
        changeMusicSource(to: .local)
    }
}

// MARK: - Convenience Extensions
extension MusicPlayerViewModel {
    func playPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func isCurrentSong(_ song: Song) -> Bool {
        return currentSong?.id == song.id
    }
    
    func getCurrentSourceName() -> String {
        return currentMusicSource.rawValue
    }
    
    func getPlayerStateDescription() -> String {
        return playerState.description
    }
}
