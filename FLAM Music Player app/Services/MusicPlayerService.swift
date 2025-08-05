import Foundation
import Combine
import AVFoundation

// MARK: - Singleton Music Player Service
class MusicPlayerService: NSObject, ObservableObject {
    static let shared = MusicPlayerService()
    
    // MARK: - Published Properties
    @Published var currentSong: Song?
    @Published var playerState: PlayerState = .idle
    @Published var playbackProgress: PlaybackProgress = PlaybackProgress(currentTime: 0, duration: 0)
    @Published var queue: [Song] = []
    @Published var currentIndex: Int = 0
    @Published var repeatMode: RepeatMode = .none
    @Published var isShuffled: Bool = false
    @Published var volume: Float = 1.0
    
    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private var currentMusicSource: MusicSourceProtocol?
    private var cancellables = Set<AnyCancellable>()
    private var observers: [PlayerNotificationProtocol] = []
    
    // MARK: - Strategy Pattern - Music Sources
    private let localMusicService = LocalMusicService()
    private let spotifyMusicService = SpotifyMusicService()
    private let audioDBService = AudioDBService()
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Public Methods
    
    // MARK: - Source Management
    func setMusicSource(_ sourceType: MusicSourceType) {
        switch sourceType {
        case .local:
            currentMusicSource = localMusicService
        case .spotify:
            currentMusicSource = spotifyMusicService
        case .audioDB:
            currentMusicSource = audioDBService
        }
    }
    
    func searchSongs(query: String) -> AnyPublisher<[Song], Error> {
        guard let source = currentMusicSource else {
            return Fail(error: MusicPlayerError.noSourceSelected)
                .eraseToAnyPublisher()
        }
        
        return source.search(query: query)
    }
    
    // MARK: - Playback Control
    func play() {
        guard let song = currentSong else {
            if !queue.isEmpty {
                playAtIndex(currentIndex)
            }
            return
        }
        
        if audioPlayer?.isPlaying == true {
            return
        }
        
        audioPlayer?.play()
        updatePlayerState(.playing)
        startProgressTimer()
    }
    
    func pause() {
        audioPlayer?.pause()
        updatePlayerState(.paused)
        stopProgressTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        updatePlayerState(.stopped)
        stopProgressTimer()
        updateProgress()
    }
    
    func skip() {
        let nextIndex = getNextIndex()
        playAtIndex(nextIndex)
    }
    
    func previous() {
        let previousIndex = getPreviousIndex()
        playAtIndex(previousIndex)
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        updateProgress()
    }
    
    // MARK: - Queue Management
    func setQueue(_ songs: [Song], startIndex: Int = 0) {
        queue = songs
        currentIndex = max(0, min(startIndex, songs.count - 1))
        notifyQueueUpdate()
        
        if !songs.isEmpty {
            playAtIndex(currentIndex)
        }
    }
    
    func addToQueue(_ song: Song) {
        queue.append(song)
        notifyQueueUpdate()
    }
    
    func removeFromQueue(at index: Int) {
        guard index < queue.count else { return }
        
        queue.remove(at: index)
        
        // Adjust current index if necessary
        if index < currentIndex {
            currentIndex -= 1
        } else if index == currentIndex && currentIndex >= queue.count {
            currentIndex = max(0, queue.count - 1)
        }
        
        notifyQueueUpdate()
    }
    
    func moveInQueue(from source: IndexSet, to destination: Int) {
        queue.move(fromOffsets: source, toOffset: destination)
        notifyQueueUpdate()
    }
    
    func shuffleQueue() {
        let currentSong = queue[safe: currentIndex]
        queue.shuffle()
        
        // Find the new index of the currently playing song
        if let song = currentSong,
           let newIndex = queue.firstIndex(of: song) {
            currentIndex = newIndex
        }
        
        isShuffled = true
        notifyQueueUpdate()
    }
    
    func clearQueue() {
        stop()
        queue.removeAll()
        currentIndex = 0
        currentSong = nil
        notifyQueueUpdate()
        notifyCurrentSongChange()
    }
    
    // MARK: - Observer Pattern
    func addObserver(_ observer: PlayerNotificationProtocol) {
        observers.append(observer)
    }
    
    func removeObserver(_ observer: PlayerNotificationProtocol) {
        // Note: This would require implementing Equatable for PlayerNotificationProtocol
        // For simplicity, we'll clear all observers or use a different approach
    }
    
    // MARK: - Private Methods
    
    private func playAtIndex(_ index: Int) {
        guard index < queue.count, index >= 0 else { return }
        
        currentIndex = index
        let song = queue[index]
        currentSong = song
        
        updatePlayerState(.loading)
        notifyCurrentSongChange()
        
        // Load song from current source
        guard let source = currentMusicSource else {
            updatePlayerState(.error("No music source selected"))
            return
        }
        
        source.loadSong(song: song)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.updatePlayerState(.error(error.localizedDescription))
                    }
                },
                receiveValue: { [weak self] audioURL in
                    self?.playSong(from: audioURL, song: song)
                }
            )
            .store(in: &cancellables)
    }
    
    private func playSong(from url: URL?, song: Song) {
        guard let url = url else {
            updatePlayerState(.error("Could not load audio file"))
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            updatePlayerState(.playing)
            startProgressTimer()
            
        } catch {
            updatePlayerState(.error("Failed to play audio: \(error.localizedDescription)"))
        }
    }
    
    private func getNextIndex() -> Int {
        switch repeatMode {
        case .one:
            return currentIndex
        case .all:
            return (currentIndex + 1) % queue.count
        case .none:
            return min(currentIndex + 1, queue.count - 1)
        }
    }
    
    private func getPreviousIndex() -> Int {
        switch repeatMode {
        case .one:
            return currentIndex
        case .all:
            return currentIndex == 0 ? queue.count - 1 : currentIndex - 1
        case .none:
            return max(currentIndex - 1, 0)
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func updateProgress() {
        guard let player = audioPlayer else { return }
        
        let progress = PlaybackProgress(
            currentTime: player.currentTime,
            duration: player.duration
        )
        
        playbackProgress = progress
        notifyProgressUpdate(progress)
    }
    
    private func updatePlayerState(_ state: PlayerState) {
        playerState = state
        notifyStateChange(state)
    }
    
    // MARK: - Notification Methods
    private func notifyStateChange(_ state: PlayerState) {
        observers.forEach { $0.playerStateDidChange(state) }
    }
    
    private func notifyProgressUpdate(_ progress: PlaybackProgress) {
        observers.forEach { $0.playbackProgressDidUpdate(progress) }
    }
    
    private func notifyQueueUpdate() {
        observers.forEach { $0.queueDidUpdate(queue) }
    }
    
    private func notifyCurrentSongChange() {
        observers.forEach { $0.currentSongDidChange(currentSong) }
    }
}

// MARK: - AVAudioPlayerDelegate
extension MusicPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            // Song finished naturally, play next
            if repeatMode == .one {
                player.currentTime = 0
                player.play()
            } else {
                let nextIndex = getNextIndex()
                if nextIndex != currentIndex || repeatMode == .all {
                    playAtIndex(nextIndex)
                } else {
                    stop()
                }
            }
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Unknown playback error"
        updatePlayerState(.error(errorMessage))
    }
}

// MARK: - Music Player Errors
enum MusicPlayerError: LocalizedError {
    case noSourceSelected
    case invalidURL
    case playbackError(String)
    
    var errorDescription: String? {
        switch self {
        case .noSourceSelected:
            return "No music source has been selected"
        case .invalidURL:
            return "Invalid audio URL"
        case .playbackError(let message):
            return "Playback error: \(message)"
        }
    }
}

