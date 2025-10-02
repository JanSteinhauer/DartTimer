//
//  SetupView.swift
//  DartTimer
//
//  Created by Steinhauer, Jan on 01.10.25.
//

import SwiftUI
import SwiftData

struct SetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var storedPlayers: [DTPlayer]
    @State private var newPlayerName = ""
    @State private var selectedMode: DTGameMode = .x01_501
    @State private var doubleIn = false
    @State private var doubleOut = true
    @State private var startingScore = 501

    let engine: GameEngine
    @Binding var selectedTab: DTTab

    var body: some View {
        NavigationStack {
            Form {
                Section("Game Mode") {
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(DTGameMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedMode == .x01_301 || selectedMode == .x01_501 {
                        Toggle("Double-In", isOn: $doubleIn)
                        Toggle("Double-Out", isOn: $doubleOut)
                        Stepper("Starting Score: \(startingScore)", value: $startingScore, in: 101...1001, step: 50)
                    } else {
                        Text("Mode-specific rules will appear here.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                // SetupView.swift (only the players section shown)
                Section("Players") {
                    HStack {
                        TextField("Add player name", text: $newPlayerName)
                        Button {
                            let name = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !name.isEmpty else { return }
                            let p = DTPlayer(name: name)
                            modelContext.insert(p)
                            try? modelContext.save()
                            newPlayerName = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .tint(.habitOrange)
                    }

                    if storedPlayers.isEmpty {
                        ContentUnavailableView(
                            "No players yet",
                            systemImage: "person.fill.badge.plus",
                            description: Text("Create players above.")
                        )
                    } else {
                        ForEach(storedPlayers) { p in
                            HStack {
                                Image(systemName: p.avatarSymbol).foregroundStyle(.primary)
                                Text(p.name)
                                Spacer()
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    engine.removePlayer(p.id, modelContext: modelContext)
                                    modelContext.delete(p)
                                    try? modelContext.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        // Note: .onDelete requires a List; we rely on swipeActions here.
                    }
                }

                


                Section {
                    Button {
                        engine.selectGameMode(selectedMode)
                        let rules = DTRules(doubleIn: doubleIn,
                                            doubleOut: doubleOut,
                                            startingScore: (selectedMode == .x01_301 ? 301 : (selectedMode == .x01_501 ? startingScore : nil)),
                                            handicap: [:])
                        engine.setRules(rules)
                        engine.addPlayers(Array(storedPlayers.prefix(8))) // cap for UI sanity
                        engine.startGame(modelContext: modelContext)
                        selectedTab = .game
                    } label: {
                        Label("Start Game", systemImage: "play.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.habitOrange)
                }
            }
            .toolbar { EditButton() }
            .navigationTitle("DartTimer")
        }
    }
}
