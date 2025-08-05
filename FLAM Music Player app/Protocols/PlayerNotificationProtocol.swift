import Foundation
import Combine

protocol PlayerNotificationProtocol {
    func playerStateDidChange(_ state: PlayerState)
    func playbackProgressDidUpdate(_ progress: PlaybackProgress)
    func queueDidUpdate(_ queue: [Song])
    func currentSongDidChange(_ song: Song?)
}
