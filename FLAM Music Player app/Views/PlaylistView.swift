import SwiftUI

struct PlaylistView: View {
    @StateObject private var viewModel = PlaylistViewModel()
    @State private var showingCreatePlaylist = false
    @State private var newPlaylistName = ""
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                searchSection
                
                // Playlists List
                playlistsList
            }
            .navigationTitle("Playlists")
            .navigationBarItems(
                trailing: Button(action: { showingCreatePlaylist = true }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingCreatePlaylist) {
                CreatePlaylistView(
                    playlistName: $newPlaylistName,
                    onCreate: {
                        viewModel.createPlaylist(name: newPlaylistName)
                        newPlaylistName = ""
                        showingCreatePlaylist = false
                    },
                    onCancel: {
                        newPlaylistName = ""
                        showingCreatePlaylist = false
                    }
                )
            }
        }
    }
    
    // MARK: - View Components
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search playlists...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
    
    private var playlistsList: some View {
        List {
            // Statistics Section
            statisticsSection
            
            // Playlists
            ForEach(filteredPlaylists) { playlist in
                NavigationLink(
                    destination: PlaylistDetailView(playlist: playlist, viewModel: viewModel)
                ) {
                    PlaylistRowView(playlist: playlist)
                }
            }
            .onDelete(perform: deletePlaylists)
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Library")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                StatisticView(
                    title: "Playlists",
                    value: "\(viewModel.totalPlaylists)",
                    icon: "music.note.list"
                )
                
                Spacer()
                
                StatisticView(
                    title: "Songs",
                    value: "\(viewModel.totalSongs)",
                    icon: "music.note"
                )
                
                Spacer()
                
                StatisticView(
                    title: "Duration",
                    value: viewModel.formattedTotalDuration,
                    icon: "clock"
                )
            }
        }
        .padding(.vertical, 8)
        .listRowBackground(Color(.systemGray6))
    }
    
    private var filteredPlaylists: [Playlist] {
        viewModel.filterPlaylists(by: searchText)
    }
    
    private func deletePlaylists(at offsets: IndexSet) {
        for index in offsets {
            let playlist = filteredPlaylists[index]
            viewModel.deletePlaylist(playlist)
        }
    }
}

// MARK: - Create Playlist View
struct CreatePlaylistView: View {
    @Binding var playlistName: String
    let onCreate: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Playlist name", text: $playlistName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Spacer()
            }
            .navigationTitle("New Playlist")
            .navigationBarItems(
                leading: Button("Cancel", action: onCancel),
                trailing: Button("Create") {
                    onCreate()
                }
                .disabled(playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
}

// MARK: - Playlist Row View
struct PlaylistRowView: View {
    let playlist: Playlist
    
    var body: some View {
        HStack {
            // Playlist Icon
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "music.note.list")
                        .foregroundColor(.white)
                        .font(.title3)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("\(playlist.songCount) song\(playlist.songCount == 1 ? "" : "s")")
                    Text("•")
                    Text(playlist.formattedDuration)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Last modified
            Text(RelativeDateTimeFormatter().localizedString(for: playlist.lastModified, relativeTo: Date()))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Statistic View
struct StatisticView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Playlist Detail View
struct PlaylistDetailView: View {
    let playlist: Playlist
    @ObservedObject var viewModel: PlaylistViewModel
    @State private var showingEditName = false
    @State private var editedName = ""
    
    var body: some View {
        List {
            // Playlist Header
            playlistHeader
            
            // Songs
            ForEach(Array(playlist.songs.enumerated()), id: \.element.id) { index, song in
                SongRowView(
                    song: song,
                    showArtwork: false,
                    onTap: {
                        viewModel.playPlaylist(playlist, startAt: index)
                    }
                )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.removeSongFromPlaylist(at: index, from: playlist)
                }
            }
            .onMove { from, to in
                viewModel.moveSongInPlaylist(from: from, to: to, in: playlist)
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarItems(
            trailing: Menu {
                Button("Edit Name") {
                    editedName = playlist.name
                    showingEditName = true
                }
                
                Button("Shuffle Play") {
                    viewModel.shufflePlaylist(playlist)
                }
                
                Button("Add to Queue") {
                    viewModel.addPlaylistToQueue(playlist)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        )
        .alert("Edit Playlist Name", isPresented: $showingEditName) {
            TextField("Playlist name", text: $editedName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                viewModel.renamePlaylist(playlist, to: editedName)
            }
        }
    }
    
    private var playlistHeader: some View {
        VStack(spacing: 16) {
            // Large artwork placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 150, height: 150)
                .overlay(
                    Image(systemName: "music.note.list")
                        .foregroundColor(.white)
                        .font(.system(size: 40))
                )
            
            VStack(spacing: 8) {
                Text(playlist.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                HStack {
                    Text("\(playlist.songCount) song\(playlist.songCount == 1 ? "" : "s")")
                    Text("•")
                    Text(playlist.formattedDuration)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            // Play button
            if !playlist.songs.isEmpty {
                Button(action: {
                    viewModel.playPlaylist(playlist)
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
                .padding(.horizontal, 40)
            }
        }
        .padding(.vertical)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Song Row View
struct SongRowView: View {
    let song: Song
    let showArtwork: Bool
    let onTap: () -> Void
    
    init(song: Song, showArtwork: Bool = true, onTap: @escaping () -> Void) {
        self.song = song
        self.showArtwork = showArtwork
        self.onTap = onTap
    }
    
    var body: some View {
        HStack {
            if showArtwork {
                // Artwork placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                            .font(.caption)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.subheadline)
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
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(song.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
                Image(systemName: song.sourceType.iconName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    PlaylistView()
}
