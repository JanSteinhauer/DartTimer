//
//  ContentView.swift
//  DartTimer
//
//  Created by Steinhauer, Jan on 01.10.25.
//

import SwiftUI
import SwiftData

enum DTTab: Hashable { case setup, game, history, settings }

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var engine = GameEngine()
    @State private var selectedTab: DTTab = .setup   // <-- add

    var body: some View {
        TabView(selection: $selectedTab) {           // <-- bind selection
            SetupView(engine: engine, selectedTab: $selectedTab)
                .tabItem { Label("Setup", systemImage: "person.3.sequence") }
                .tag(DTTab.setup)

            GameView(engine: engine)
                .tabItem { Label("Game", systemImage: "target") }
                .tag(DTTab.game)

            HistoryView(engine: engine)
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(DTTab.history)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(DTTab.settings)
        }
    }
}
