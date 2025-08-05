import Foundation

struct MusicSource: Identifiable, Equatable {
    let id = UUID()
    let type: MusicSourceType
    let isAvailable: Bool
    let description: String
    
    init(type: MusicSourceType, isAvailable: Bool = true, description: String = "") {
        self.type = type
        self.isAvailable = isAvailable
        self.description = description.isEmpty ? type.rawValue : description
    }
}
