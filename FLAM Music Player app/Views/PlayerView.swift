import SwiftUI

struct PlayerView: View {
    @StateObject private var viewModel = MusicPlayerViewModel()
    @State private var showingQueue = false
    @State private var showingVolumeSlider = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Current Song Info
            currentSongSection
            
            // Progress Bar
            progressSection
            
            // Main Controls
            mainControlsSection
            
            // Secondary Controls
            secondaryControlsSection
            
            // Queue Button
            queueButton
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
        .sheet(isPresented: $showingQueue) {
            QueueView(viewModel: viewModel)
        }
    }
    
    // MARK: - View Components
    
    private var currentSongSection: some View {
        VStack(spacing: 8) {
            if let song = viewModel.currentSong {
                // Artwork placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    )
                
                // Song Details
                VStack(spacing: 4) {
                    Text(song.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(song.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let album = song.album {
                        Text(album)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .multilineTextAlignment(.center)
            } else {
                // No song playing
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "music.note.tv")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No Song Playing")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            // Progress Bar
            HStack {
                Text(viewModel.formattedCurrentTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
                Slider(
                    value: Binding(
                        get: { viewModel.playbackProgress.currentTime },
                        set: { viewModel.seek(to: $0) }
                    ),
                    in: 0...max(viewModel.playbackProgress.duration, 1)
                )
                .accentColor(.blue)
                
                Text(viewModel.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            // Player State
            Text(viewModel.getPlayerStateDescription())
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var mainControlsSection: some View {
        HStack(spacing: 40) {
            // Previous Button
            Button(action: viewModel.skipToPrevious) {
                Image(systemName: "backward.fill")
                    .font(.title)
                    .foregroundColor(viewModel.canPlayPrevious ? .primary : .gray)
            }
            .disabled(!viewModel.canPlayPrevious)
            
            // Play/Pause Button
            Button(action: viewModel.playPause) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
            }
            .disabled(viewModel.currentSong == nil)
            
            // Next Button
            Button(action: viewModel.skipToNext) {
                Image(systemName: "forward.fill")
                    .font(.title)
                    .foregroundColor(viewModel.canPlayNext ? .primary : .gray)
            }
            .disabled(!viewModel.canPlayNext)
        }
    }
    
    private var secondaryControlsSection: some View {
        HStack(spacing: 30) {
            // Shuffle Button
            Button(action: viewModel.toggleShuffle) {
                Image(systemName: "shuffle")
                    .font(.title3)
                    .foregroundColor(viewModel.isShuffled ? .blue : .gray)
            }
            
            // Repeat Button
            Button(action: viewModel.toggleRepeat) {
                Image(systemName: viewModel.repeatMode.iconName)
                    .font(.title3)
                    .foregroundColor(viewModel.repeatMode != .none ? .blue : .gray)
            }
            
            // Volume Button
            Button(action: { showingVolumeSlider.toggle() }) {
                Image(systemName: volumeIcon)
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            .popover(isPresented: $showingVolumeSlider) {
                VStack {
                    Text("Volume")
                        .font(.caption)
                        .padding(.top)
                    
                    Slider(
                        value: Binding(
                            get: { viewModel.volume },
                            set: { viewModel.setVolume($0) }
                        ),
                        in: 0...1
                    )
                    .frame(width: 200)
                    .padding()
                }
                .frame(width: 240, height: 80)
            }
        }
    }
    
    private var queueButton: some View {
        HStack {
            Button(action: { showingQueue = true }) {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("Queue (\(viewModel.queue.count))")
                    Spacer()
                    Text(viewModel.queuePosition)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var volumeIcon: String {
        if viewModel.volume == 0 {
            return "speaker.slash"
        } else if viewModel.volume < 0.3 {
            return "speaker.1"
        } else if viewModel.volume < 0.7 {
            return "speaker.2"
        } else {
            return "speaker.3"
        }
    }
}

// MARK: - Queue View
struct QueueView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(viewModel.queue.enumerated()), id: \.offset) { index, song in
                    QueueRowView(
                        song: song,
                        isCurrentSong: index == viewModel.musicPlayerService.currentIndex,
                        onTap: {
                            // Play from this position
                            viewModel.setQueue(viewModel.queue, startAt: index)
                        }
                    )
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.removeFromQueue(at: index)
                    }
                }
                .onMove { from, to in
                    // Handle queue reordering
                }
            }
            .navigationTitle("Queue")
            .navigationBarItems(
                leading: Button("Clear") {
                    viewModel.clearQueue()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Queue Row View
struct QueueRowView: View {
    let song: Song
    let isCurrentSong: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            // Current song indicator
            Image(systemName: isCurrentSong ? "speaker.wave.2" : "music.note")
                .foregroundColor(isCurrentSong ? .blue : .gray)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(isCurrentSong ? .semibold : .regular)
                    .foregroundColor(isCurrentSong ? .blue : .primary)
                
                Text(song.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(song.formattedDuration)
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    PlayerView()
}
