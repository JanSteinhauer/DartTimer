//
//  GameView.swift
//  DartTimer
//
//  Created by Steinhauer, Jan on 01.10.25.
//

import SwiftUI
import SwiftData

struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\DTPlayer.name, order: .forward)]) private var storedPlayers: [DTPlayer]
    let engine: GameEngine

    var body: some View {
        VStack(spacing: 12) {
            header
            scoreboard
            hitPad
            history
        }
        .padding()
        .navigationTitle("Game")
    }

    // MARK: - UI Sections

    private var header: some View {
        HStack {
            Text(engine.game?.mode.rawValue ?? "No Game").font(.headline)
            Spacer()
            if let pid = engine.highlightCurrentPlayer(),
               let p = storedPlayers.first(where: { $0.id == pid }) {
                Label("Turn: \(p.name)", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.subheadline).bold()
            } else {
                Text("No active game").foregroundStyle(.secondary)
            }
        }
    }

    private var scoreboard: some View {
        VStack(spacing: 8) {
            ForEach(engine.showScoreboard(), id: \.playerID) { row in
                HStack {
                    Text(playerName(for: row.playerID))
                    Spacer()
                    Text("\(row.value)").monospacedDigit().font(.title3)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 12).fill(.gray.opacity(0.08)))
            }

            if let win = engine.winnerID {
                Text("🎉 Winner: \(playerName(for: win))")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .padding(.top, 6)
            }
        }
    }

    private var hitPad: some View {
        // Simple segmented controls for multiplier and number
        VStack(spacing: 10) {
            Text("Enter Hit").font(.headline)

            HitInput(engine: engine)
                .disabled(engine.winnerID != nil)
                .animation(.easeInOut, value: engine.winnerID)

            HStack {
                Button(role: .destructive) {
                    engine.undoLastThrow(modelContext: modelContext)
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward.circle")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    engine.switchTurn(modelContext: modelContext)
                } label: {
                    Label("Switch Turn", systemImage: "arrowshape.turn.up.right.circle")
                }
                .buttonStyle(.borderedProminent)
                .tint(.habitOrange)
            }
            .padding(.top, 6)
        }
        .padding(.vertical, 8)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("History").font(.headline)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(engine.showHistory(for: nil), id: \.self) { h in
                        Text(formatHit(h))
                            .padding(.horizontal, 8).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 10).fill(.gray.opacity(0.12)))
                            .monospaced()
                    }
                }.padding(.vertical, 4)
            }
        }
    }

    private func playerName(for id: UUID) -> String {
        storedPlayers.first(where: { $0.id == id })?.name ?? "Unknown"
    }

    private func formatHit(_ h: DTHit) -> String {
        switch h.kind {
        case .miss: return "—"
        case .bull25: return "25"
        case .bull50: return "50"
        default:
            return "\(h.kind == .double ? "D" : (h.kind == .triple ? "T" : "S"))\(h.number ?? 0)"
        }
    }
}

// MARK: - HitInput

private struct HitInput: View {
    @Environment(\.modelContext) private var modelContext
    let engine: GameEngine
    @State private var multiplier: DTHitKind = .single
    @State private var number: Int = 20

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Picker("Mult", selection: $multiplier) {
                    Text("S").tag(DTHitKind.single)
                    Text("D").tag(DTHitKind.double)
                    Text("T").tag(DTHitKind.triple)
                }
                .pickerStyle(.segmented)

                Stepper("Num: \(number)", value: $number, in: 1...20)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            HStack {
                Button { submit(kind: .miss) } label: {
                    Text("Miss")
                }.buttonStyle(.bordered)

                Button { submit(kind: .bull25) } label: {
                    Text("Bull 25")
                }.buttonStyle(.bordered)

                Button { submit(kind: .bull50) } label: {
                    Text("Bull 50")
                }.buttonStyle(.bordered)

                Spacer()
                Button {
                    submit(kind: multiplier)
                } label: {
                    Label("Enter", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.habitOrange)
            }
        }
    }

    private func submit(kind: DTHitKind) {
        guard let pid = engine.highlightCurrentPlayer(),
              let player = try? modelContext.fetch(FetchDescriptor<DTPlayer>()).first(where: { $0.id == pid }) else { return }
        engine.recordThrow(player: player, dartNumber: number, hit: kind, modelContext: modelContext)
    }
}
