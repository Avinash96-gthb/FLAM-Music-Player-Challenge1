import Foundation
import SwiftUI
import AVFoundation

// MARK: - TimeInterval Extension
extension TimeInterval {
    var formattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedLongTime: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Collection Extension
extension Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}

// MARK: - String Extension
extension String {
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isNotEmpty: Bool {
        return !trimmed.isEmpty
    }
    
    func truncated(to length: Int, trailing: String = "...") -> String {
        guard self.count > length else { return self }
        return String(self.prefix(length)) + trailing
    }
}

// MARK: - URL Extension
extension URL {
    var isAudioFile: Bool {
        let audioExtensions = Constants.FileExtensions.supportedAudioFormats
        return audioExtensions.contains(pathExtension.lowercased())
    }
}

// MARK: - Color Extension
extension Color {
    static let playerBackground = Color(.systemBackground)
    static let playerSecondary = Color(.secondarySystemBackground)
    static let playerTertiary = Color(.tertiarySystemBackground)
    
    // Custom colors for the app
    static let accent = Color.blue
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    // Gradient colors
    static let gradientStart = Color.blue.opacity(0.6)
    static let gradientEnd = Color.purple.opacity(0.6)
}

// MARK: - View Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Custom Corner Radius Shape
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Animation Extensions
extension Animation {
    static let playerAnimation = Animation.easeInOut(duration: Constants.UI.animationDuration)
    static let quickAnimation = Animation.easeInOut(duration: 0.15)
    static let slowAnimation = Animation.easeInOut(duration: 0.6)
}

// MARK: - Date Extension
extension Date {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - FileManager Extension
extension FileManager {
    func documentsDirectory() -> URL {
        return urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func musicDirectory() -> URL {
        return documentsDirectory().appendingPathComponent("Music", isDirectory: true)
    }
    
    func createMusicDirectoryIfNeeded() {
        let musicDir = musicDirectory()
        if !fileExists(atPath: musicDir.path) {
            try? createDirectory(at: musicDir, withIntermediateDirectories: true)
        }
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    func setObject<T: Codable>(_ object: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(object) {
            set(data, forKey: key)
        }
    }
    
    func getObject<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

// MARK: - AVAudioSession Extension
extension AVAudioSession {
    func configureForPlayback() throws {
        try setCategory(.playback, mode: .default, options: [])
        try setActive(true)
    }
    
    func configureForRecording() throws {
        try setCategory(.record, mode: .default, options: [])
        try setActive(true)
    }
}

// MARK: - Publishers Extension
import Combine

extension Publishers {
    static func debounceTextField<S: Scheduler>(
        for dueTime: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> AnyPublisher<String, Never> where S : Scheduler {
        return NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification)
            .compactMap { ($0.object as? UITextField)?.text }
            .debounce(for: dueTime, scheduler: scheduler)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - Haptic Feedback Extension
extension UIImpactFeedbackGenerator {
    static func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}
