import SwiftUI

struct SourceSelectionView: View {
    @StateObject private var viewModel = SourceSelectionViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Source Picker
                sourcePickerSection
                
                // Search Section
                searchSection
                
                // Content Section
                contentSection
            }
            .navigationTitle("Music Sources")
        }
    }
    
    // MARK: - View Components
    
    private var sourcePickerSection: some View {
        VStack(spacing: 16) {
            Text("Select Music Source")
                .font(.headline)
                .padding(.top)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(viewModel.availableSources, id: \.id) { source in
                    SourceCardView(
                        source: source,
                        isSelected: source.type == viewModel.selectedSource,
                        onTap: {
                            if source.isAvailable {
                                viewModel.selectSource(source.type)
                            } else {
                                viewModel.initializeSource(source.type)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            
            if viewModel.isInitializing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Initializing \(viewModel.selectedSourceName)...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            if let error = viewModel.initializationError {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
        }
        .padding(.bottom)
        .background(Color(.systemGray6))
    }
    
    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search \(viewModel.selectedSourceName)...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        viewModel.searchMusic(query: searchText)
                    }
                
                if viewModel.isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal)
            
            if !searchText.isEmpty && !viewModel.isSearching {
                Button("Search") {
                    viewModel.searchMusic(query: searchText)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var contentSection: some View {
        TabView {
            // Search Results Tab
            if viewModel.hasSearchResults || viewModel.isSearchQueryValid {
                searchResultsTab
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
            }
            
            // Recommendations Tab
            recommendationsTab
                .tabItem {
                    Image(systemName: "star")
                    Text("Discover")
                }
        }
    }
    
    private var searchResultsTab: some View {
        VStack {
            if viewModel.hasSearchResults {
                HStack {
                    Text(viewModel.searchResultsCount)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Play All") {
                        viewModel.playSearchResults()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.horizontal)
                
                List {
                    ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { index, song in
                        SearchResultRowView(
                            song: song,
                            onPlay: {
                                viewModel.playSong(song)
                            },
                            onAddToQueue: {
                                viewModel.addSongToQueue(song)
                            }
                        )
                    }
                }
            } else if viewModel.isSearchQueryValid && !viewModel.isSearching {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results",
                    message: "No songs found for '\(searchText)'"
                )
            } else {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "Search Music",
                    message: "Enter a song, artist, or album name to search"
                )
            }
        }
    }
    
    private var recommendationsTab: some View {
        VStack {
            if viewModel.isLoadingRecommendations {
                ProgressView("Loading recommendations...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasRecommendations {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Recommended for You")
                            .font(.headline)
                        Text(viewModel.recommendationsCount)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Play All") {
                        viewModel.playRecommendations()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.horizontal)
                
                List {
                    ForEach(Array(viewModel.recommendations.enumerated()), id: \.element.id) { index, song in
                        SearchResultRowView(
                            song: song,
                            onPlay: {
                                viewModel.playSong(song)
                            },
                            onAddToQueue: {
                                viewModel.addSongToQueue(song)
                            }
                        )
                    }
                }
                .refreshable {
                    viewModel.loadRecommendations()
                }
            } else {
                EmptyStateView(
                    icon: "star",
                    title: "No Recommendations",
                    message: "Pull to refresh or try a different source"
                )
            }
        }
    }
}

// MARK: - Source Card View
struct SourceCardView: View {
    let source: MusicSource
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: source.type.iconName)
                .font(.system(size: 30))
                .foregroundColor(isSelected ? .white : (source.isAvailable ? .blue : .gray))
            
            VStack(spacing: 4) {
                Text(source.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(source.isAvailable ? "Available" : "Unavailable")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : (source.isAvailable ? .green : .red))
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue : Color(.systemBackground))
                .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 0 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .opacity(source.isAvailable ? 1.0 : 0.6)
    }
}

// MARK: - Search Result Row View
struct SearchResultRowView: View {
    let song: Song
    let onPlay: () -> Void
    let onAddToQueue: () -> Void
    
    var body: some View {
        HStack {
            // Song artwork placeholder
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 45, height: 45)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundColor(.gray)
                        .font(.caption)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let album = song.album {
                    Text(album)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(song.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
                HStack(spacing: 8) {
                    Button(action: onAddToQueue) {
                        Image(systemName: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: onPlay) {
                        Image(systemName: "play.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SourceSelectionView()
}
