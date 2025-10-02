//
//  GameEngine.swift
//  DartTimer
//
//  Created by Steinhauer, Jan on 01.10.25.
//

import Foundation
import SwiftData

/// Central scoring & state coordinator for DartTimer.
/// Exposes the functions you listed; views call these.
@Observable
final class GameEngine {

    // MARK: - Live State
    private(set) var game: DTGame?
    private(set) var players: [DTPlayer] = []
    private(set) var allThrows: [DTThrow] = [] // chronological
    private(set) var turnDartIndex: Int = 0 // 0..2 within a player's 3-dart turn
    private(set) var hasDoubledIn: Set<UUID> = [] // for X01 with Double-In
    private(set) var winnerID: UUID?

    // Derived
    var currentPlayerID: UUID? {
        guard let g = game, !g.playerIDs.isEmpty else { return nil }
        return g.playerIDs[g.currentTurnIndex % g.playerIDs.count]
    }

    // MARK: - Game Setup Functions

    func selectGameMode(_ mode: DTGameMode) {
        _selectedMode = mode
        print("[GameEngine] Selected game mode: \(mode.rawValue)")
    }

    func setNumberOfPlayers(_ n: Int) {
        _pendingPlayerCount = max(1, n)
        print("[GameEngine] Pending number of players set to: \(_pendingPlayerCount)")
    }

    func addPlayers(_ newPlayers: [DTPlayer]) {
        players = newPlayers
        print("[GameEngine] Added \(newPlayers.count) players.")
    }

    func setRules(_ rules: DTRules) {
        _pendingRules = rules
        print("[GameEngine] Custom rules set: doubleIn=\(rules.doubleIn), doubleOut=\(rules.doubleOut), start=\(rules.startingScore ?? 0)")
    }

    // MARK: - Gameplay Functions
    func startGame(modelContext: ModelContext) {
        let mode = _selectedMode ?? .x01_501
        let rules = _pendingRules ?? defaultRules(for: mode)
        let g = DTGame(mode: mode, players: players, rules: rules)

        if case .x01_301 = mode { g.rules.startingScore = 301 }
        if case .x01_501 = mode { g.rules.startingScore = 501 }

        // Initialize X01 scoreboard
        if mode == .x01_301 || mode == .x01_501 {
            let base = g.rules.startingScore ?? 501
            for id in g.playerIDs {
                let adj = base + (g.rules.handicap[id] ?? 0)
                g.scoreboard[id] = adj
                print("[GameEngine] Player \(id) starting score: \(adj)")
            }
        }

        modelContext.insert(g)
        try? modelContext.save()
        self.game = g
        self.allThrows.removeAll()
        self.turnDartIndex = 0
        self.winnerID = nil
        self.hasDoubledIn = []

        print("[GameEngine] Game started with mode=\(mode.rawValue) and \(players.count) players.")
    }

    /// Enter one dart result.
    func recordThrow(player: DTPlayer, dartNumber: Int, hit: DTHitKind, modelContext: ModelContext) {
        guard let g = game, g.isActive, player.id == currentPlayerID else {
            print("[GameEngine] ⚠️ Invalid throw: either no game active or wrong player.")
            return
        }

        // Build normalized hit
        var normalized: DTHit
        switch hit {
        case .bull25, .bull50:
            normalized = DTHit(number: nil, kind: hit)
        case .miss:
            normalized = DTHit(number: nil, kind: .miss)
        default:
            let n = max(1, min(20, dartNumber))
            normalized = DTHit(number: n, kind: hit)
        }

        print("[GameEngine] Player \(player.name) threw: \(normalized)")

        // Persist throw
        let t = DTThrow(playerID: player.id, orderIndex: allThrows.count, hit: normalized)
        modelContext.insert(t)
        try? modelContext.save()
        allThrows.append(t)

        // Apply scoring
        applyThrowToState(playerID: player.id, hit: normalized, modelContext: modelContext)

        // Advance dart index or turn
        if winnerID == nil {
            if turnDartIndex >= 2 {
                print("[GameEngine] End of 3 darts, switching turn.")
                switchTurn(modelContext: modelContext)
            } else {
                turnDartIndex += 1
                print("[GameEngine] Dart index advanced to \(turnDartIndex).")
            }
        }
    }
    
    // GameEngine.swift
    func removePlayer(_ playerID: UUID, modelContext: ModelContext) {
        // Remove from local list used by UI
        players.removeAll { $0.id == playerID }

        guard let g = game else { return }

        // If the player is in an active/loaded game, clean references
        if let idx = g.playerIDs.firstIndex(of: playerID) {
            let wasCurrent = (currentPlayerID == playerID)
            g.playerIDs.remove(at: idx)
            g.scoreboard[playerID] = nil

            // Clamp currentTurnIndex
            if !g.playerIDs.isEmpty {
                g.currentTurnIndex = g.currentTurnIndex % g.playerIDs.count
                if wasCurrent { turnDartIndex = 0 } // start fresh for next player
            } else {
                // No players left -> end game gracefully (no winner)
                g.isActive = false
                winnerID = nil
            }
            try? modelContext.save()
        }
    }



    func calculateScore(playerID: UUID, hit: DTHit, mode: DTGameMode) -> (newValue: Int, isBust: Bool) {
        guard let g = game else { return (0, false) }

        switch mode {
        case .x01_301, .x01_501:
            let current = g.scoreboard[playerID] ?? (g.rules.startingScore ?? 501)

            // Double-In gate
            if g.rules.doubleIn && !hasDoubledIn.contains(playerID) {
                // progress only if hit is a double or bull50 (optional interpretation: allow D-bull to count as double-in)
                let qualifies = (hit.kind == .double) || (hit.kind == .bull50)
                let newValue = qualifies ? max(0, current - hit.rawPoints) : current
                let bust = newValue < 0
                return (bust ? current : newValue, bust)
            }

            // Normal / Double-Out
            let target = current - hit.rawPoints
            print("[GameEngine] Calculating score: current=\(current), hit=\(hit.rawPoints), target=\(target)")
            if target < 0 { return (current, true) } // bust
            if target == 0 {
                if g.rules.doubleOut {
                    let isDoubleOut = (hit.kind == .double) || (hit.kind == .bull50)
                    return (isDoubleOut ? 0 : current, !isDoubleOut)
                } else {
                    return (0, false)
                }
            }
            return (target, false)

        case .cricket, .aroundTheClock:
            // Stub: return unchanged; specific rules handled elsewhere later.
            return (0, false)
        }
    }

    func switchTurn(modelContext: ModelContext) {
        guard let g = game, g.isActive else { return }
        g.currentTurnIndex = (g.currentTurnIndex + 1) % g.playerIDs.count
        turnDartIndex = 0
        try? modelContext.save()
        print("[GameEngine] ➡️ Switched turn. Current player index=\(g.currentTurnIndex)")
    }

    func undoLastThrow(modelContext: ModelContext) {
        guard let last = allThrows.popLast() else { return }
        print("[GameEngine] Undo last throw of player=\(last.playerID)")
        modelContext.delete(last)
        try? modelContext.save()
        recomputeStateFromHistory()
    }

    // MARK: - Game Logic Functions

    func checkWinCondition(gameMode: DTGameMode, playerScore: Int, boardState: Any?) -> Bool {
        switch gameMode {
        case .x01_301, .x01_501:
            return playerScore == 0
        case .cricket, .aroundTheClock:
            // Implement later.
            return false
        }
    }

    func applySpecialRules() {
        // Hook for future variants like cut-throat Cricket, Shanghai, etc.
    }

    func trackStatistics() -> [UUID: (dartsThrown: Int, ppd: Double)] {
        guard let g = game else { return [:] }
        var result: [UUID: (Int, Double)] = [:]
        for id in g.playerIDs {
            let playerThrows = allThrows.filter { $0.playerID == id }
            let darts = playerThrows.count
            // Points per dart for X01: derive from starting score minus remaining
            if g.mode == .x01_301 || g.mode == .x01_501 {
                let start = g.rules.startingScore ?? 501
                let remaining = g.scoreboard[id] ?? start
                let scored = start - remaining
                let ppd = darts > 0 ? Double(scored) / Double(darts) : 0
                result[id] = (darts, ppd)
            } else {
                result[id] = (darts, 0)
            }
        }
        return result
    }

    // MARK: - UI / Display Helper Functions

    func showScoreboard() -> [(playerID: UUID, value: Int)] {
        guard let g = game else { return [] }
        switch g.mode {
        case .x01_301, .x01_501:
            return g.playerIDs.map { ($0, g.scoreboard[$0] ?? (g.rules.startingScore ?? 501)) }
        default:
            return []
        }
    }

    func highlightCurrentPlayer() -> UUID? { currentPlayerID }

    func showHistory(for playerID: UUID?) -> [DTHit] {
        allThrows
            .filter { playerID == nil || $0.playerID == playerID }
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { $0.decodedHit }
    }

    // MARK: - Persistence / Extras

    func saveGameState(modelContext: ModelContext) {
        try? modelContext.save()
    }

    func loadGameState(existingGame: DTGame, players: [DTPlayer], throwsInDB: [DTThrow]) {
        self.game = existingGame
        self.players = players
        self.allThrows = throwsInDB.sorted { $0.orderIndex < $1.orderIndex }
        recomputeStateFromHistory()
    }

    func exportStatsCSV() -> String {
        let stats = trackStatistics()
        var rows = ["player, darts, ppd"]
        for p in players {
            let s = stats[p.id] ?? (0,0)
            rows.append("\(p.name),\(s.dartsThrown),\(String(format: "%.2f", s.ppd))")
        }
        return rows.joined(separator: "\n")
    }

    // MARK: - Internals

    private var _selectedMode: DTGameMode?
    private var _pendingPlayerCount: Int = 1
    private var _pendingRules: DTRules?

    private func defaultRules(for mode: DTGameMode) -> DTRules {
        switch mode {
        case .x01_301: return DTRules(doubleIn: false, doubleOut: true, startingScore: 301)
        case .x01_501: return DTRules(doubleIn: false, doubleOut: true, startingScore: 501)
        case .cricket: return DTRules(doubleIn: false, doubleOut: false, startingScore: nil)
        case .aroundTheClock: return DTRules(doubleIn: false, doubleOut: false, startingScore: nil)
        }
    }

    private func applyThrowToState(
        playerID: UUID,
        hit: DTHit,
        modelContext: ModelContext?,
        persist: Bool = true
    ) {
        guard let g = game else { return }

        switch g.mode {
        case .x01_301, .x01_501:
            if g.rules.doubleIn && !hasDoubledIn.contains(playerID) {
                if (hit.kind == .double) || (hit.kind == .bull50) {
                    hasDoubledIn.insert(playerID)
                }
            }

            let before = g.scoreboard[playerID] ?? (g.rules.startingScore ?? 501)
            let (after, isBust) = calculateScore(playerID: playerID, hit: hit, mode: g.mode)

            if isBust {
                if persist, let ctx = modelContext {
                    bustCurrentTurn(for: playerID, originalBefore: before, modelContext: ctx)
                } else {
                    // simulate bust in memory only
                    g.scoreboard[playerID] = before
                    hasDoubledIn.remove(playerID) // optional policy
                    g.currentTurnIndex = (g.currentTurnIndex + 1) % g.playerIDs.count
                    turnDartIndex = 0
                }
            } else {
                g.scoreboard[playerID] = after
                if persist, let ctx = modelContext { try? ctx.save() }

                if checkWinCondition(gameMode: g.mode, playerScore: after, boardState: nil) {
                    if persist, let ctx = modelContext {
                        endGame(winnerID: playerID, modelContext: ctx)
                    } else {
                        winnerID = playerID
                        g.isActive = false
                    }
                }
            }

        case .cricket, .aroundTheClock:
            // TODO
            break
        }
    }


    private func bustCurrentTurn(for playerID: UUID, originalBefore: Int, modelContext: ModelContext) {
        guard let g = game else { return }
        // Remove up to 3 latest throws by this player in this turn
        var removed: [DTThrow] = []
        var count = 0
        for t in allThrows.reversed() {
            if t.playerID == playerID && count < 3 {
                removed.append(t)
                count += 1
            } else {
                break
            }
        }
        for r in removed {
            if let idx = allThrows.firstIndex(where: { $0.id == r.id }) {
                allThrows.remove(at: idx)
            }
            modelContext.delete(r)
        }
        g.scoreboard[playerID] = originalBefore
        hasDoubledIn.remove(playerID) // optional: revert double-in if you *require* the double to be part of valid scoring; choose policy
        try? modelContext.save()
        // End turn immediately after bust
        switchTurn(modelContext: modelContext)
    }

    private func endGame(winnerID: UUID, modelContext: ModelContext) {
        guard let g = game else { return }
        self.winnerID = winnerID
        g.isActive = false
        print("[GameEngine] 🎉 Game ended. Winner=\(winnerID)")
        let completed = DTCompletedGame(mode: g.mode, winnerID: winnerID, players: g.playerIDs, throwsCount: allThrows.count)
        modelContext.insert(completed)
        try? modelContext.save()
    }

    private func recomputeStateFromHistory() {
        guard let g = game else { return }

        // Reset state
        turnDartIndex = 0
        winnerID = nil
        hasDoubledIn = []

        if g.mode == .x01_301 || g.mode == .x01_501 {
            let base = g.rules.startingScore ?? 501
            for id in g.playerIDs {
                g.scoreboard[id] = base + (g.rules.handicap[id] ?? 0)
            }
        }

        var dartsInCurrentTurn = 0

        for t in allThrows.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            // ensure rotation matches the stored throw's player
            while t.playerID != g.playerIDs[g.currentTurnIndex % g.playerIDs.count] {
                g.currentTurnIndex = (g.currentTurnIndex + 1) % g.playerIDs.count
                dartsInCurrentTurn = 0
            }

            // Re-apply throw without persistence
            applyThrowToState(playerID: t.playerID, hit: t.decodedHit, modelContext: nil, persist: false)

            // If someone won during replay, we can stop
            if winnerID != nil { break }

            // Advance within the 3-dart turn unless a bust already advanced the turn
            let expectedPlayer = g.playerIDs[g.currentTurnIndex % g.playerIDs.count]
            if expectedPlayer == t.playerID {
                dartsInCurrentTurn += 1
                if dartsInCurrentTurn >= 3 {
                    g.currentTurnIndex = (g.currentTurnIndex + 1) % g.playerIDs.count
                    dartsInCurrentTurn = 0
                }
            } else {
                // turn already advanced due to bust
                dartsInCurrentTurn = 0
            }
        }

        turnDartIndex = dartsInCurrentTurn
    }

}

