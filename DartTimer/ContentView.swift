//
//  ContentView.swift
//  DartTimer
//
//  Created by Steinhauer, Jan on 01.10.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var engine = GameEngine()

    var body: some View {
        TabView {
            SetupView(engine: engine)
                .tabItem { Label("Setup", systemImage: "person.3.sequence") }

            GameView(engine: engine)
                .tabItem { Label("Game", systemImage: "target") }

            HistoryView(engine: engine)
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
