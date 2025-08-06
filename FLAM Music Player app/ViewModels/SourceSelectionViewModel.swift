import Foundation
import Combine

class SourceSelectionViewModel: ObservableObject {
    @Published var availableSources: [MusicSource] = []
    @Published var selectedSource: MusicSourceType = .local
    @Published var isInitializing: Bool = false
    @Published var initializationError: String?
    @Published var searchResults: [Song] = []
    @Published var isSearching: Bool = false
    @Published var searchQuery: String = ""
    @Published var recommendations: [Song] = []
    @Published var isLoadingRecommendations: Bool = false
    
    private let musicPlayerService = MusicPlayerService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Strategy Pattern - Music Sources
    private let localMusicService = LocalMusicService()
    private let spotifyMusicService = SpotifyMusicService()
    private let audioDBService = AudioDBService()
    
    init() {
        initializeAvailableSources()
        initializeSource(.local)
        loadRecommendations()
    }
    
    // MARK: - Source Management
    
    func selectSource(_ sourceType: MusicSourceType) {
        selectedSource = sourceType
        musicPlayerService.setMusicSource(sourceType)
        
        // Clear previous results
        searchResults.removeAll()
        searchQuery = ""
        
        // Load recommendations for the new source
        loadRecommendations()
    }
    
    func initializeSource(_ sourceType: MusicSourceType) {
        print("🔄 Initializing source: \(sourceType)")
        isInitializing = true
        initializationError = nil
        
        let source = getSourceService(for: sourceType)
        print("🎪 Got source service: \(source.sourceName)")
        
        source.initialize()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    print("🏁 Source initialization completion: \(completion)")
                    self?.isInitializing = false
                    
                    if case .failure(let error) = completion {
                        print("❌ Initialization failed: \(error)")
                        self?.initializationError = error.localizedDescription
                        self?.updateSourceAvailability(sourceType, isAvailable: false)
                    } else {
                        print("✅ Initialization successful")
                        self?.updateSourceAvailability(sourceType, isAvailable: true)
                    }
                },
                receiveValue: { [weak self] success in
                    print("📈 Initialization value received: \(success)")
                    if success {
                        self?.selectSource(sourceType)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    
    // MARK: - Search Functionality
    
    func searchMusic(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults.removeAll()
            return
        }
        
        searchQuery = query
        isSearching = true
        
        let source = getSourceService(for: selectedSource)
        
        source.search(query: query)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isSearching = false
                    
                    if case .failure(let error) = completion {
                        print("Search error: \(error.localizedDescription)")
                        self?.searchResults.removeAll()
                    }
                },
                receiveValue: { [weak self] songs in
                    self?.searchResults = songs
                }
            )
            .store(in: &cancellables)
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults.removeAll()
    }
    
    // MARK: - Recommendations
    
    func loadRecommendations() {
        isLoadingRecommendations = true
        
        let source = getSourceService(for: selectedSource)
        
        source.getRecommendations()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingRecommendations = false
                    
                    if case .failure(let error) = completion {
                        print("Recommendations error: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] songs in
                    self?.recommendations = songs
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Playback Integration
    
    func playSong(_ song: Song) {
        musicPlayerService.setQueue([song], startIndex: 0)
    }
    
    func addSongToQueue(_ song: Song) {
        musicPlayerService.addToQueue(song)
    }
    
    func playSearchResults(startingAt index: Int = 0) {
        guard !searchResults.isEmpty else { return }
        musicPlayerService.setQueue(searchResults, startIndex: index)
    }
    
    func playRecommendations(startingAt index: Int = 0) {
        guard !recommendations.isEmpty else { return }
        musicPlayerService.setQueue(recommendations, startIndex: index)
    }
    
    // MARK: - Source Information
    
    func getSourceDescription(_ sourceType: MusicSourceType) -> String {
        switch sourceType {
        case .local:
            return "Play music files stored on your device"
        case .spotify:
            return "Stream music from Spotify (Mock implementation)"
        case .audioDB:
            return "Discover music from TheAudioDB online database"
        }
    }
    
    func getSourceIcon(_ sourceType: MusicSourceType) -> String {
        return sourceType.iconName
    }
    
    func isSourceAvailable(_ sourceType: MusicSourceType) -> Bool {
        return availableSources.first { $0.type == sourceType }?.isAvailable ?? false
    }
    
    // MARK: - Private Methods
    
    private func initializeAvailableSources() {
        availableSources = [
            MusicSource(
                type: .local,
                isAvailable: true,
                description: "Local music files on your device"
            ),
            MusicSource(
                type: .spotify,
                isAvailable: false,
                description: "Spotify streaming service (Mock)"
            ),
            MusicSource(
                type: .audioDB,
                isAvailable: true,
                description: "TheAudioDB online music database"
            )
        ]
        
        // Initialize local source by default
        selectSource(.local)
    }
    
    private func getSourceService(for sourceType: MusicSourceType) -> MusicSourceProtocol {
        switch sourceType {
        case .local:
            return localMusicService
        case .spotify:
            return spotifyMusicService
        case .audioDB:
            return audioDBService
        }
    }
    
    private func updateSourceAvailability(_ sourceType: MusicSourceType, isAvailable: Bool) {
        if let index = availableSources.firstIndex(where: { $0.type == sourceType }) {
            let updatedSource = MusicSource(
                type: sourceType,
                isAvailable: isAvailable,
                description: availableSources[index].description
            )
            availableSources[index] = updatedSource
        }
    }
}

// MARK: - Computed Properties
extension SourceSelectionViewModel {
    var hasSearchResults: Bool {
        return !searchResults.isEmpty
    }
    
    var hasRecommendations: Bool {
        return !recommendations.isEmpty
    }
    
    var isSearchQueryValid: Bool {
        return !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var selectedSourceName: String {
        return selectedSource.rawValue
    }
    
    var selectedSourceDescription: String {
        return getSourceDescription(selectedSource)
    }
    
    var searchResultsCount: String {
        let count = searchResults.count
        return count == 1 ? "1 result" : "\(count) results"
    }
    
    var recommendationsCount: String {
        let count = recommendations.count
        return count == 1 ? "1 song" : "\(count) songs"
    }
}

// MARK: - Convenience Methods
extension SourceSelectionViewModel {
    func refreshCurrentSource() {
        initializeSource(selectedSource)
    }
    
    func getSongDisplayInfo(_ song: Song) -> String {
        return "\(song.title) - \(song.artist)"
    }
    
    func getSongDuration(_ song: Song) -> String {
        return song.formattedDuration
    }
    
    func canPlaySong(_ song: Song) -> Bool {
        return isSourceAvailable(song.sourceType)
    }
}
