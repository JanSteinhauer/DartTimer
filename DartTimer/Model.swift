//
//  Model.swift
//  DartTimer
//
//  Created by Steinhauer, Jan on 01.10.25.
//

import Foundation
import SwiftData

// MARK: - Enums

enum DTGameMode: String, Codable, CaseIterable, Identifiable {
    case x01_301 = "301"
    case x01_501 = "501"
    case cricket = "Cricket"
    case aroundTheClock = "Around the Clock"

    var id: String { rawValue }
}

enum DTHitKind: String, Codable {
    case miss
    case single
    case double
    case triple
    case bull25     // outer bull (25)
    case bull50     // inner bull (50)

    var multiplier: Int {
        switch self {
        case .miss: return 0
        case .single: return 1
        case .double: return 2
        case .triple: return 3
        case .bull25: return 1
        case .bull50: return 2
        }
    }
}

struct DTHit: Codable, Hashable {
    var number: Int? // 1...20 for segments, nil for bull/miss
    var kind: DTHitKind
    var rawPoints: Int {
        switch kind {
        case .miss: return 0
        case .bull25: return 25
        case .bull50: return 50
        default:
            return (number ?? 0) * kind.multiplier
        }
    }
}

// MARK: - SwiftData Models

@Model
final class DTPlayer {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var avatarSymbol: String

    init(id: UUID = UUID(), name: String, colorHex: String = "#FF9F0A", avatarSymbol: String = "person.fill") {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.avatarSymbol = avatarSymbol
    }
}

@Model
final class DTThrow {
    var id: UUID
    var playerID: UUID
    var orderIndex: Int
    var hit: Data // encoded DTHit

    init(playerID: UUID, orderIndex: Int, hit: DTHit) {
        self.id = UUID()
        self.playerID = playerID
        self.orderIndex = orderIndex
        self.hit = try! JSONEncoder().encode(hit)
    }

    var decodedHit: DTHit { (try? JSONDecoder().decode(DTHit.self, from: hit)) ?? DTHit(number: nil, kind: .miss) }
}

@Model
final class DTGame {
    var id: UUID
    var modeRaw: String
    var createdAt: Date
    var isActive: Bool
    var playerIDs: [UUID]
    var currentTurnIndex: Int
    var rules: DTRules
    var scoreboard: [UUID: Int] // for X01: remaining points

    init(mode: DTGameMode, players: [DTPlayer], rules: DTRules) {
        self.id = UUID()
        self.modeRaw = mode.rawValue
        self.createdAt = Date()
        self.isActive = true
        self.playerIDs = players.map { $0.id }
        self.currentTurnIndex = 0
        self.rules = rules
        self.scoreboard = [:]
    }

    var mode: DTGameMode { DTGameMode(rawValue: modeRaw) ?? .x01_501 }
}

@Model
final class DTCompletedGame {
    var id: UUID
    var finishedAt: Date
    var modeRaw: String
    var winnerID: UUID?
    var players: [UUID]
    var throwsCount: Int
    var notes: String?

    init(mode: DTGameMode, winnerID: UUID?, players: [UUID], throwsCount: Int, notes: String? = nil) {
        self.id = UUID()
        self.finishedAt = Date()
        self.modeRaw = mode.rawValue
        self.winnerID = winnerID
        self.players = players
        self.throwsCount = throwsCount
        self.notes = notes
    }

    var mode: DTGameMode { DTGameMode(rawValue: modeRaw) ?? .x01_501 }
}

@Model
final class DTSettings {
    var id: UUID
    var soundOn: Bool
    var hapticsOn: Bool
    var themeHex: String

    init(soundOn: Bool = true, hapticsOn: Bool = true, themeHex: String = "#FF9F0A") {
        self.id = UUID()
        self.soundOn = soundOn
        self.hapticsOn = hapticsOn
        self.themeHex = themeHex
    }
}

// MARK: - Rules

struct DTRules: Codable, Hashable {
    var doubleIn: Bool
    var doubleOut: Bool
    var startingScore: Int? // for X01 only
    var handicap: [UUID: Int] // per player added or subtracted

    init(doubleIn: Bool = false, doubleOut: Bool = true, startingScore: Int? = 501, handicap: [UUID: Int] = [:]) {
        self.doubleIn = doubleIn
        self.doubleOut = doubleOut
        self.startingScore = startingScore
        self.handicap = handicap
    }
}
