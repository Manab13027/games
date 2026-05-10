# Kids Arcade Platform — Design Spec
**Date:** 2026-05-10  
**Engine:** Godot 4 + GDScript  
**Platform:** Standalone desktop (Mac / Windows / Linux)  
**Audience:** Tweens/teens (12+)  
**Scope:** Hub launcher + growing arcade library (10+ games); first game: 3D Paddleball

---

## 1. Architecture

**Pattern:** Single Godot 4 monorepo — one project, one export, all games as scenes.

### Folder Structure
```
games/                          ← Godot project root
├── hub/
│   ├── Hub.tscn                ← main launcher scene
│   ├── GameCard.tscn           ← reusable game tile component
│   └── hub.gd
├── games/
│   ├── paddleball/
│   │   ├── PaddleBall.tscn     ← game entry scene
│   │   ├── LevelSelect.tscn    ← level/difficulty picker
│   │   ├── Arena.tscn
│   │   ├── Paddle.tscn
│   │   ├── Ball.tscn
│   │   └── scripts/
│   └── (future games here)
├── shared/
│   ├── theme.tres              ← global UI theme (neon arcade)
│   ├── sounds/
│   ├── fonts/
│   └── autoloads/
│       ├── GameManager.gd
│       ├── SaveManager.gd
│       └── AudioManager.gd
└── project.godot
```

### Scene Flow
```
Main.tscn (boot/splash)
  → Hub.tscn (game selection)
    → LevelSelect.tscn (per-game level picker)
      → PaddleBall.tscn (gameplay)
        → ScoreScreen.tscn (results)
          → Hub.tscn or retry
```

### Autoload Singletons
| Singleton | Responsibility |
|---|---|
| `GameManager` | Scene switching, current game state, scene registry |
| `SaveManager` | High scores, unlocked levels, player settings (JSON on disk) |
| `AudioManager` | Global BGM, SFX bus, volume control |

---

## 2. Hub Launcher

**Visual style:** Neon Arcade — dark sci-fi background (`#070714`), glowing grid lines, neon-bordered game cards, purple/blue accent palette.

### Layout
- Full-screen launcher with animated neon grid background
- Game cards in a scrollable grid (3 columns)
- Each card shows: game icon, name, star rating, best score, PLAY button
- Locked games show a padlock and "Coming Soon"
- Top bar: platform logo, settings gear, player high score

### Game Card States
- **Available** — glowing border, animated hover effect, shows best score
- **Locked** — dimmed, padlock icon, unlocks when previous game is completed
- **New** — pulsing "NEW" badge

---

## 3. Paddleball Game

### Concept
A futuristic 3D enclosed arena. The player controls an energy paddle at the bottom of the court. A high-speed ball ricochets off walls, ceiling, and floor. Floating glowing targets appear inside the arena. The player must keep the ball alive while destroying targets to chain combos and maximise score.

### Arena
- Fully enclosed 3D room: floor, ceiling, four walls
- Reflective neon grid floor with PBR materials
- Glowing wall edges (emissive trim)
- Third-person angled camera with subtle cinematic follow, slight screen shake on hard impacts, dynamic FOV increase at high speed
- Three unlockable arena themes:
  - **Neon Cyber** — default, purple/blue grid, holographic walls
  - **Space Station** — stars outside transparent walls, zero-gravity sections at high levels
  - **Reactor Core** — orange/red industrial, steam vents, warning lights

### Paddle
- Rendered as an energy shield / plasma bar (not a flat rectangle)
- Glowing emissive material, reactive hit sparks on ball contact
- Moves left/right (and slightly forward/back on higher levels) via mouse or keyboard
- Angle of contact imparts spin to the ball

### Ball
- Rigid body physics — preserves velocity through bounces
- Spin applied based on paddle contact angle
- Leaves a particle trail (GPU particles)
- Emits sparks on wall/target collisions
- **Slow-motion trigger** — activates for 1.5s when an ULTRA combo (x10) is reached
- Gradually accelerates over time within each level session

### Floating Targets
- Appear inside the arena at various heights and positions
- Colors indicate point value: blue (100), orange (300), red (500)
- Some targets move laterally or rotate on higher levels
- Destroying a target adds to the combo multiplier

### Combo System
| Streak | Multiplier | Effect |
|---|---|---|
| 1–2 hits | x1 | Normal scoring |
| 3–5 hits | x3 | Score colour changes to gold |
| 6–9 hits | x6 | Screen edge glow pulses |
| 10+ hits | x10 ULTRA | 1.5s slow-motion + screen flash |
- Missing the ball (losing a life) resets the combo to x1

### HUD
- Top-left: current score
- Top-center: level name + arena theme
- Top-right: remaining lives (❤️ icons)
- Right edge: live combo multiplier
- Brief on-screen flash text for combo milestones ("COMBO x5!", "ULTRA!")

### Difficulty Levels
| Level | Name | Ball Speed | Paddle Width | Targets | Special |
|---|---|---|---|---|---|
| 1 | Rookie | Slow | Wide | None | — |
| 2 | Cadet | Medium | Standard | Static targets | Basic combos |
| 3 | Pilot | Fast | Standard | Moving targets | Spin mechanics active |
| 4 | Ace | Very fast | Narrow | Multi-ball | Moving obstacles |
| 5 | Legend | Max | Narrow | Chaos mode | Moving walls |
| ∞ | Endless | Escalating | Narrow | Procedural | Random obstacles, local leaderboard |

Endless mode unlocks after completing Legend.

### Level Completion Condition
- Destroy all targets in the arena without losing all lives
- Endless mode: survive as long as possible; no win condition

### Visual Effects (Godot 4 features used)
- `WorldEnvironment` with bloom, glow, and SSAO
- `OmniLight3D` / `SpotLight3D` per target (dynamic coloured lighting)
- GPU particles for ball trail, impact sparks, target destruction explosion
- Screen-space motion blur at high ball speed
- `ShaderMaterial` for emissive paddle and wall trim
- Physics interpolation enabled for smooth 60fps rendering

### Audio
- Thumpy synth hit SFX on ball/wall contact (pitch-shifts with speed)
- Satisfying crunch on target destruction
- Combo milestone voice/chime
- Looping atmospheric synth BGM per arena theme (fades/crossfades between levels)

---

## 4. Save System

Stored as JSON at `user://save.json` (Godot's user data directory, OS-appropriate path).

```json
{
  "high_scores": {
    "paddleball": { "rookie": 0, "cadet": 0, "pilot": 0, "ace": 0, "legend": 0, "endless": 0 }
  },
  "unlocked_levels": { "paddleball": ["rookie"] },
  "settings": { "master_volume": 1.0, "sfx_volume": 1.0, "music_volume": 0.8, "fullscreen": true }
}
```

---

## 5. Out of Scope (v1)

- Multiplayer / networking
- Online leaderboards (endless mode leaderboard is local for v1)
- Mobile / web export
- More than one game (paddleball is the only game in v1; hub shows others as "Coming Soon")
- Controller/gamepad support (keyboard + mouse only for v1)

---

## 6. Success Criteria

- [ ] Hub launcher opens, shows Paddleball card, launches the game
- [ ] All 5 difficulty levels are playable end-to-end
- [ ] Endless mode unlocks after Legend completion
- [ ] Combo system works correctly (multiplier, ULTRA slow-mo)
- [ ] GPU particles, bloom, and screen shake are active and performant (60fps)
- [ ] Scores persist across sessions via SaveManager
- [ ] All three arena themes are selectable and visually distinct
- [ ] Game runs as a standalone desktop export on macOS
