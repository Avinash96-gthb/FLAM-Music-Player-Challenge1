//
//  FLAM_Music_Player_appApp.swift
//  FLAM Music Player app
//
//  Created by A Avinash Chidambaram on 06/08/25.
//

import SwiftUI

@main
struct FLAM_Music_Player_appApp: App {
    init() {
        print("🚀 App starting up...")
        // Force initialize the music player service
        let _ = MusicPlayerService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("📱 ContentView appeared")
                }
        }
    }
}
