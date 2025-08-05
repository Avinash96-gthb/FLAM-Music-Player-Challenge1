import Foundation
import Combine
import AVFoundation

class PlaybackManager: NSObject, ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    weak var delegate: PlaybackManagerDelegate?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Public Methods
    
    func loadAudio(from url: URL) -> Bool {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            
            return true
        } catch {
            print("Failed to load audio: \(error)")
            return false
        }
    }
    
    func play() {
        guard let player = audioPlayer else { return }
        
        player.rate = playbackRate
        player.play()
        isPlaying = true
        startProgressTimer()
        
        delegate?.playbackDidStart()
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
        
        delegate?.playbackDidPause()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
        stopProgressTimer()
        
        delegate?.playbackDidStop()
    }
    
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        
        player.currentTime = min(max(time, 0), duration)
        currentTime = player.currentTime
        
        delegate?.playbackDidSeek(to: currentTime)
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        audioPlayer?.rate = rate
    }
    
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
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
        
        currentTime = player.currentTime
        delegate?.playbackProgressDidUpdate(currentTime: currentTime, duration: duration)
    }
}

// MARK: - AVAudioPlayerDelegate
extension PlaybackManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopProgressTimer()
        
        if flag {
            delegate?.playbackDidFinish()
        } else {
            delegate?.playbackDidFail(with: "Playback failed")
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlaying = false
        stopProgressTimer()
        
        let errorMessage = error?.localizedDescription ?? "Unknown decode error"
        delegate?.playbackDidFail(with: errorMessage)
    }
}

// MARK: - PlaybackManager Delegate
protocol PlaybackManagerDelegate: AnyObject {
    func playbackDidStart()
    func playbackDidPause()
    func playbackDidStop()
    func playbackDidFinish()
    func playbackDidSeek(to time: TimeInterval)
    func playbackProgressDidUpdate(currentTime: TimeInterval, duration: TimeInterval)
    func playbackDidFail(with error: String)
}
