# 🎯 DartTimer

A modern SwiftUI app that replaces the broken logic of a physical dart machine.
Manage players, select game modes, keep score, and track history — all from your iPhone or iPad.

Built in **SwiftUI + SwiftData** with the clean, minimal look & feel of `HabiTimer`.

---

## ✨ Features

### 🏗 Core Game Setup

* Choose game mode: **301, 501, Cricket, Around the Clock** (X01 fully implemented, others extendable).
* Add multiple players (with name, avatar, and color).
* Configure rules:

  * Double-In / Double-Out
  * Starting score (for X01)
  * Handicaps (per player)

### 🎮 Gameplay

* Record darts with quick input controls:

  * Segment hits (Single, Double, Triple)
  * Bullseye (25, 50)
  * Miss
* Automatic scoring & bust detection
* Turn management (3 darts per player, auto advance)
* Undo last throw
* Win detection (X01: exact zero with optional Double-Out)

### 📊 Stats & History

* Live scoreboard with highlight for current player
* History view of past throws
* Track darts thrown, points per dart (PPD) for each player
* Completed games archive (date, mode, winner, throws count)
* Export stats as CSV

### ⚙️ Extras

* Settings for theme color, sound, and haptics
* Persistent game state (resume where you left off)
* Extendable design for new game modes (Cricket, Shanghai, Killer, etc.)

---

## 🖥 Screenshots

*(add screenshots here once you run on device)*

---

## 🛠 Project Structure

```
DartTimer/
│
├── DartTimerApp.swift       # Entry point
├── ContentView.swift        # Main TabView
│
├── Models.swift             # SwiftData models (Player, Game, Throw, Settings)
├── GameEngine.swift         # Core game logic & scoring engine
│
├── SetupView.swift          # Configure new game (players, rules)
├── GameView.swift           # Live game UI (scoreboard, hit entry, history)
├── HistoryView.swift        # Completed games archive
├── SettingsView.swift       # App settings
│
└── Resources/               # Assets, icons, etc.
```

---

## 🚀 Getting Started

1. Clone the repo

   ```bash
   git clone https://github.com/yourusername/DartTimer.git
   cd DartTimer
   ```

2. Open in Xcode (15+)

   ```bash
   open DartTimer.xcodeproj
   ```

3. Run on simulator or device.

---

## 🔧 Implementation Notes

* **SwiftData** stores players, games, throws, and settings.
* **GameEngine** is a pure Swift class coordinating rules & scoring.
* Recomputes game state from history after undo → guarantees consistency.
* Input UI designed for **manual entry** (tap after each throw).
  (Future: Camera / smart board integration possible.)

---

## 📈 Roadmap

* [ ] Implement **Cricket** scoring & win condition
* [ ] Implement **Around the Clock** mode
* [ ] Leaderboard with player averages over multiple games
* [ ] Export to **PDF** (with charts and stats)
* [ ] Multiplayer over network (Game Center / Firebase)
* [ ] Optional integration with smart dartboards

---

## 📜 License

MIT License

