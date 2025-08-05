import Foundation
import Combine

class QueueManager: ObservableObject {
    @Published var queue: [Song] = []
    @Published var currentIndex: Int = 0
    @Published var isShuffled: Bool = false
    @Published var repeatMode: RepeatMode = .none
    
    private var originalQueue: [Song] = [] // For unshuffling
    private var originalIndex: Int = 0
    
    weak var delegate: QueueManagerDelegate?
    
    // MARK: - Computed Properties
    
    var currentSong: Song? {
        guard currentIndex < queue.count, currentIndex >= 0 else { return nil }
        return queue[currentIndex]
    }
    
    var hasNext: Bool {
        switch repeatMode {
        case .none:
            return currentIndex < queue.count - 1
        case .one, .all:
            return !queue.isEmpty
        }
    }
    
    var hasPrevious: Bool {
        switch repeatMode {
        case .none:
            return currentIndex > 0
        case .one, .all:
            return !queue.isEmpty
        }
    }
    
    var isEmpty: Bool {
        return queue.isEmpty
    }
    
    var count: Int {
        return queue.count
    }
    
    // MARK: - Queue Management
    
    func setQueue(_ songs: [Song], startAt index: Int = 0) {
        queue = songs
        originalQueue = songs
        currentIndex = max(0, min(index, songs.count - 1))
        originalIndex = currentIndex
        isShuffled = false
        
        delegate?.queueDidUpdate()
        delegate?.currentSongDidChange(currentSong)
    }
    
    func addSong(_ song: Song) {
        queue.append(song)
        if !isShuffled {
            originalQueue.append(song)
        }
        
        delegate?.queueDidUpdate()
    }
    
    func addSongs(_ songs: [Song]) {
        queue.append(contentsOf: songs)
        if !isShuffled {
            originalQueue.append(contentsOf: songs)
        }
        
        delegate?.queueDidUpdate()
    }
    
    func insertSong(_ song: Song, at index: Int) {
        let insertIndex = max(0, min(index, queue.count))
        queue.insert(song, at: insertIndex)
        
        // Adjust current index if necessary
        if insertIndex <= currentIndex {
            currentIndex += 1
        }
        
        if !isShuffled {
            originalQueue.insert(song, at: insertIndex)
            if insertIndex <= originalIndex {
                originalIndex += 1
            }
        }
        
        delegate?.queueDidUpdate()
    }
    
    func removeSong(at index: Int) {
        guard index < queue.count else { return }
        
        let removedSong = queue.remove(at: index)
        
        // Adjust current index
        if index < currentIndex {
            currentIndex -= 1
        } else if index == currentIndex {
            // Current song was removed
            if currentIndex >= queue.count {
                currentIndex = max(0, queue.count - 1)
            }
            delegate?.currentSongDidChange(currentSong)
        }
        
        // Remove from original queue if not shuffled
        if !isShuffled {
            if let originalIndex = originalQueue.firstIndex(of: removedSong) {
                originalQueue.remove(at: originalIndex)
            }
        }
        
        delegate?.queueDidUpdate()
    }
    
    func moveSong(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex < queue.count,
              destinationIndex < queue.count,
              sourceIndex != destinationIndex else { return }
        
        let song = queue.remove(at: sourceIndex)
        queue.insert(song, at: destinationIndex)
        
        // Adjust current index
        if sourceIndex == currentIndex {
            currentIndex = destinationIndex
        } else if sourceIndex < currentIndex && destinationIndex >= currentIndex {
            currentIndex -= 1
        } else if sourceIndex > currentIndex && destinationIndex <= currentIndex {
            currentIndex += 1
        }
        
        delegate?.queueDidUpdate()
        delegate?.currentSongDidChange(currentSong)
    }
    
    func clearQueue() {
        queue.removeAll()
        originalQueue.removeAll()
        currentIndex = 0
        originalIndex = 0
        isShuffled = false
        
        delegate?.queueDidUpdate()
        delegate?.currentSongDidChange(nil)
    }
    
    // MARK: - Navigation
    
    func moveToNext() -> Song? {
        let nextIndex = getNextIndex()
        if nextIndex != currentIndex || repeatMode == .all {
            currentIndex = nextIndex
            delegate?.currentSongDidChange(currentSong)
            return currentSong
        }
        return nil
    }
    
    func moveToPrevious() -> Song? {
        let previousIndex = getPreviousIndex()
        if previousIndex != currentIndex || repeatMode == .all {
            currentIndex = previousIndex
            delegate?.currentSongDidChange(currentSong)
            return currentSong
        }
        return nil
    }
    
    func moveToIndex(_ index: Int) -> Song? {
        guard index >= 0, index < queue.count else { return nil }
        
        currentIndex = index
        delegate?.currentSongDidChange(currentSong)
        return currentSong
    }
    
    // MARK: - Shuffle & Repeat
    
    func toggleShuffle() {
        if isShuffled {
            unshuffle()
        } else {
            shuffle()
        }
    }
    
    func shuffle() {
        guard !queue.isEmpty else { return }
        
        // Store original state
        if !isShuffled {
            originalQueue = queue
            originalIndex = currentIndex
        }
        
        // Get current song to maintain its position
        let currentSong = self.currentSong
        
        // Shuffle the queue
        queue.shuffle()
        
        // Find the new position of the current song
        if let song = currentSong,
           let newIndex = queue.firstIndex(of: song) {
            currentIndex = newIndex
        } else {
            currentIndex = 0
        }
        
        isShuffled = true
        delegate?.queueDidUpdate()
        delegate?.shuffleStateDidChange(true)
    }
    
    func unshuffle() {
        guard isShuffled else { return }
        
        queue = originalQueue
        currentIndex = originalIndex
        isShuffled = false
        
        delegate?.queueDidUpdate()
        delegate?.currentSongDidChange(currentSong)
        delegate?.shuffleStateDidChange(false)
    }
    
    func setRepeatMode(_ mode: RepeatMode) {
        repeatMode = mode
        delegate?.repeatModeDidChange(mode)
    }
    
    func toggleRepeatMode() {
        switch repeatMode {
        case .none:
            setRepeatMode(.all)
        case .all:
            setRepeatMode(.one)
        case .one:
            setRepeatMode(.none)
        }
    }
    
    // MARK: - Private Methods
    
    private func getNextIndex() -> Int {
        guard !queue.isEmpty else { return 0 }
        
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
        guard !queue.isEmpty else { return 0 }
        
        switch repeatMode {
        case .one:
            return currentIndex
        case .all:
            return currentIndex == 0 ? queue.count - 1 : currentIndex - 1
        case .none:
            return max(currentIndex - 1, 0)
        }
    }
}

// MARK: - QueueManager Delegate
protocol QueueManagerDelegate: AnyObject {
    func queueDidUpdate()
    func currentSongDidChange(_ song: Song?)
    func shuffleStateDidChange(_ isShuffled: Bool)
    func repeatModeDidChange(_ mode: RepeatMode)
}
