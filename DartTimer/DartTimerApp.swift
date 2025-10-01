//
//  DartTimerApp.swift
//  DartTimer
//
//  Created by Steinhauer, Jan on 01.10.25.
//

import SwiftUI
import SwiftData

extension Color {
    static let habitOrange = Color(red: 255/255, green: 159/255, blue: 10/255)
}

@main
struct DartTimerApp: App {
    init() { /* notifications later if needed */ }
    var body: some Scene {
        WindowGroup {
            ContentView().tint(.habitOrange)
        }
        .modelContainer(for: [DTPlayer.self, DTGame.self, DTThrow.self, DTCompletedGame.self, DTSettings.self])
    }
}

