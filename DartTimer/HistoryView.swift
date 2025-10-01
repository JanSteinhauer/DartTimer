//
//  HistoryView.swift
//  DartTimer
//
//  Created by Steinhauer, Jan on 01.10.25.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    let engine: GameEngine
    @Query(sort: [SortDescriptor(\DTCompletedGame.finishedAt, order: .reverse)])
    private var completed: [DTCompletedGame]
    @Query private var players: [DTPlayer]

    var body: some View {
        NavigationStack {
            List {
                if completed.isEmpty {
                    ContentUnavailableView("No completed games", systemImage: "trophy", description: Text("Finish a game to see history."))
                } else {
                    ForEach(completed) { cg in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(cg.mode.rawValue).font(.headline)
                                Spacer()
                                Text(cg.finishedAt, style: .date).foregroundStyle(.secondary)
                            }
                            if let win = cg.winnerID {
                                Text("Winner: \(name(win))").font(.subheadline).foregroundStyle(.green)
                            }
                            Text("Players: \(cg.players.map { name($0) }.joined(separator: ", "))").font(.footnote)
                            Text("Throws: \(cg.throwsCount)").font(.footnote).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Completed")
        }
    }

    private func name(_ id: UUID) -> String {
        players.first(where: { $0.id == id })?.name ?? "Unknown"
    }
}
