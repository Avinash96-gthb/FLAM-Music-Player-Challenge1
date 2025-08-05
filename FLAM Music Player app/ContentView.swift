//
//  ContentView.swift
//  FLAM Music Player app
//
//  Created by A Avinash Chidambaram on 06/08/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var musicPlayerViewModel = MusicPlayerViewModel()
    
    var body: some View {
        TabView {
            // Player Tab
            PlayerView()
                .tabItem {
                    Image(systemName: "play.circle")
                    Text("Player")
                }
            
            // Music Sources Tab
            SourceSelectionView()
                .tabItem {
                    Image(systemName: "globe")
                    Text("Browse")
                }
            
            // Playlists Tab
            PlaylistView()
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("Playlists")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
