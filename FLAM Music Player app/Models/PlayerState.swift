import Foundation

// MARK: - Player State Enum
enum PlayerState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case stopped
    case error(String)
    
    var isPlaying: Bool {
        return self == .playing
    }
    
    var description: String {
        switch self {
        case .idle:
            return "Idle"
        case .loading:
            return "Loading..."
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        case .stopped:
            return "Stopped"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

// MARK: - Playback Progress
struct PlaybackProgress: Equatable {
    let currentTime: TimeInterval
    let duration: TimeInterval
    
    var progress: Double {
        guard duration > 0, !duration.isNaN, !duration.isInfinite,
              !currentTime.isNaN, !currentTime.isInfinite else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }
    
    var formattedCurrentTime: String {
        return formatTime(currentTime)
    }
    
    var formattedDuration: String {
        return formatTime(duration)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard !time.isNaN && !time.isInfinite && time >= 0 else { return "0:00" }
        
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}


// MARK: - Repeat Mode
enum RepeatMode: String, Codable, CaseIterable {
    case none
    case one
    case all
    
    var iconName: String {
        switch self {
        case .none:
            return "repeat"
        case .one:
            return "repeat.1"
        case .all:
            return "repeat"
        }
    }
    
    var description: String {
        switch self {
        case .none:
            return "No Repeat"
        case .one:
            return "Repeat One"
        case .all:
            return "Repeat All"
        }
    }
}
