# Kids Arcade Platform — Paddleball Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone Godot 4 desktop application with a neon arcade hub launcher and a fully featured 3D paddleball game with 5 difficulty levels, combo scoring, GPU particle VFX, and three arena themes.

**Architecture:** Single Godot 4 monorepo — all games live as scene folders under `games/`, shared logic in autoload singletons, hub launcher as the main entry point. Scene flow: Main (boot) → Hub → LevelSelect → PaddleBall (gameplay) → ScoreScreen → back to Hub.

**Tech Stack:** Godot 4.3+, GDScript, GUT (Godot Unit Test plugin v9+), macOS/Windows/Linux desktop export.

---

## File Map

| File | Responsibility |
|---|---|
| `project.godot` | Window config, autoloads, physics settings |
| `Main.tscn` | Boot scene, transitions to Hub |
| `hub/Hub.tscn` + `Hub.gd` | Full-screen launcher grid, game card rendering |
| `hub/GameCard.tscn` + `GameCard.gd` | Reusable game tile: icon, name, score, state |
| `shared/autoloads/GameManager.gd` | Scene switching, current game/level state |
| `shared/autoloads/SaveManager.gd` | JSON persistence: high scores, unlocks, settings |
| `shared/autoloads/AudioManager.gd` | BGM/SFX bus, track registration, crossfade |
| `games/paddleball/LevelConfig.gd` | Static level data for all 5 levels + endless |
| `games/paddleball/ComboSystem.gd` | Pure logic: hit counting, multiplier, ULTRA trigger |
| `games/paddleball/Arena.tscn` + `Arena.gd` | 3D enclosed room, themes, moving walls/obstacles |
| `games/paddleball/Paddle.tscn` + `Paddle.gd` | Energy paddle, mouse/kb movement, spin impart |
| `games/paddleball/Ball.tscn` + `Ball.gd` | RigidBody3D, speed escalation, trail particles |
| `games/paddleball/Target.tscn` + `Target.gd` | Floating target, static/moving, point value |
| `games/paddleball/HUD.tscn` + `HUD.gd` | Score, lives, combo display, flash text overlay |
| `games/paddleball/PaddleBall.tscn` + `PaddleBall.gd` | Game controller: ties all components together |
| `games/paddleball/LevelSelect.tscn` + `LevelSelect.gd` | Level/difficulty picker UI |
| `games/paddleball/ScoreScreen.tscn` + `ScoreScreen.gd` | Results: final score, high score, retry/hub |
| `tests/test_save_manager.gd` | GUT tests for SaveManager |
| `tests/test_combo_system.gd` | GUT tests for ComboSystem |
| `tests/test_level_config.gd` | GUT tests for LevelConfig |

---

## Task 1: Godot 4 Project Setup + GUT

**Files:**
- Create: `project.godot`
- Create: `addons/gut/` (GUT plugin)
- Create: `.gitignore`
- Create: `tests/` directory

- [ ] **Step 1: Install Godot 4.3+**

  Download from https://godotengine.org/download — get the **Standard** build (not .NET unless you want C#). Verify:
  ```bash
  godot --version
  # Expected: 4.3.stable or higher
  ```

- [ ] **Step 2: Create Godot project**

  Open Godot, click **New Project**, set:
  - Project Name: `KidsArcade`
  - Project Path: `/Users/fighter/Documents/Projects_Folder/games`
  - Renderer: **Forward+** (required for bloom, SSAO, GPU particles)
  
  Click **Create & Edit**.

- [ ] **Step 3: Configure project settings**

  Go to **Project → Project Settings** and set:
  
  | Setting | Value |
  |---|---|
  | Display → Window → Size → Viewport Width | 1920 |
  | Display → Window → Size → Viewport Height | 1080 |
  | Display → Window → Mode | Fullscreen |
  | Physics → 3D → Default Gravity | 9.8 |
  | Application → Run → Main Scene | `res://Main.tscn` |

- [ ] **Step 4: Install GUT plugin**

  In Godot editor: **AssetLib** tab → search "GUT" → install **Gut-Godot Unit Testing** v9+.
  
  Then: **Project → Project Settings → Plugins** → enable GUT.

- [ ] **Step 5: Create folder structure**

  In the Godot FileSystem panel, create these folders:
  ```
  hub/
  games/paddleball/
  shared/autoloads/
  shared/fonts/
  shared/sounds/
  tests/
  addons/   (created by GUT install)
  ```

- [ ] **Step 6: Create .gitignore**

  Create `/Users/fighter/Documents/Projects_Folder/games/.gitignore`:
  ```
  .godot/
  *.import
  export_presets.cfg
  .superpowers/
  ```

- [ ] **Step 7: Commit**

  ```bash
  cd /Users/fighter/Documents/Projects_Folder/games
  git add project.godot .gitignore addons/ tests/
  git commit -m "chore: init Godot 4 project with GUT testing"
  ```

---

## Task 2: SaveManager Autoload

**Files:**
- Create: `shared/autoloads/SaveManager.gd`
- Create: `tests/test_save_manager.gd`

- [ ] **Step 1: Write the failing test**

  Create `tests/test_save_manager.gd`:
  ```gdscript
  extends GutTest

  var sm: SaveManager

  func before_each() -> void:
      sm = SaveManager.new()
      # Use a temp save path for tests
      sm._save_path = "user://test_save.json"
      sm._data = sm._default_data()

  func test_default_high_score_is_zero() -> void:
      assert_eq(sm.get_high_score("paddleball", "rookie"), 0)

  func test_set_high_score_persists_higher_value() -> void:
      sm.set_high_score("paddleball", "rookie", 500)
      assert_eq(sm.get_high_score("paddleball", "rookie"), 500)

  func test_set_high_score_ignores_lower_value() -> void:
      sm.set_high_score("paddleball", "rookie", 500)
      sm.set_high_score("paddleball", "rookie", 100)
      assert_eq(sm.get_high_score("paddleball", "rookie"), 500)

  func test_rookie_unlocked_by_default() -> void:
      assert_true(sm.is_level_unlocked("paddleball", "rookie"))

  func test_cadet_locked_by_default() -> void:
      assert_false(sm.is_level_unlocked("paddleball", "cadet"))

  func test_unlock_level_works() -> void:
      sm.unlock_level("paddleball", "cadet")
      assert_true(sm.is_level_unlocked("paddleball", "cadet"))

  func test_get_setting_returns_default() -> void:
      assert_eq(sm.get_setting("master_volume", 1.0), 1.0)
  ```

- [ ] **Step 2: Run test to verify it fails**

  In Godot editor: open the GUT scene (`addons/gut/gut_scene.tscn`), click **Run All**. Expected: errors about `SaveManager` not having the methods.
  
  Or via CLI:
  ```bash
  godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_save_manager.gd
  ```

- [ ] **Step 3: Implement SaveManager**

  Create `shared/autoloads/SaveManager.gd`:
  ```gdscript
  extends Node

  var _save_path: String = "user://save.json"
  var _data: Dictionary = {}

  func _ready() -> void:
      load_game()

  func load_game() -> void:
      if not FileAccess.file_exists(_save_path):
          _data = _default_data()
          _write_file()
          return
      var file = FileAccess.open(_save_path, FileAccess.READ)
      var parsed = JSON.parse_string(file.get_as_text())
      file.close()
      _data = parsed if parsed is Dictionary else _default_data()

  func get_high_score(game: String, level: String) -> int:
      return _data.get("high_scores", {}).get(game, {}).get(level, 0)

  func set_high_score(game: String, level: String, score: int) -> void:
      if not _data.has("high_scores"):
          _data["high_scores"] = {}
      if not _data["high_scores"].has(game):
          _data["high_scores"][game] = {}
      if score > get_high_score(game, level):
          _data["high_scores"][game][level] = score
          _write_file()

  func is_level_unlocked(game: String, level: String) -> bool:
      return level in _data.get("unlocked_levels", {}).get(game, [])

  func unlock_level(game: String, level: String) -> void:
      if not _data.has("unlocked_levels"):
          _data["unlocked_levels"] = {}
      if not _data["unlocked_levels"].has(game):
          _data["unlocked_levels"][game] = []
      if level not in _data["unlocked_levels"][game]:
          _data["unlocked_levels"][game].append(level)
          _write_file()

  func get_setting(key: String, default_value: Variant) -> Variant:
      return _data.get("settings", {}).get(key, default_value)

  func set_setting(key: String, value: Variant) -> void:
      if not _data.has("settings"):
          _data["settings"] = {}
      _data["settings"][key] = value
      _write_file()

  func _write_file() -> void:
      var file = FileAccess.open(_save_path, FileAccess.WRITE)
      file.store_string(JSON.stringify(_data))
      file.close()

  func _default_data() -> Dictionary:
      return {
          "high_scores": {
              "paddleball": {
                  "rookie": 0, "cadet": 0, "pilot": 0,
                  "ace": 0, "legend": 0, "endless": 0
              }
          },
          "unlocked_levels": {"paddleball": ["rookie"]},
          "settings": {
              "master_volume": 1.0, "sfx_volume": 1.0,
              "music_volume": 0.8, "fullscreen": true
          }
      }
  ```

- [ ] **Step 4: Register SaveManager as autoload**

  **Project → Project Settings → Autoload** → click the folder icon, select `shared/autoloads/SaveManager.gd`, set name to `SaveManager`, enable **Singleton**. Click **Add**.

- [ ] **Step 5: Run tests to verify they pass**

  ```bash
  godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_save_manager.gd
  # Expected: 7 tests passed, 0 failed
  ```

- [ ] **Step 6: Commit**

  ```bash
  git add shared/autoloads/SaveManager.gd tests/test_save_manager.gd project.godot
  git commit -m "feat(save): add SaveManager autoload with GUT tests"
  ```

---

## Task 3: GameManager Autoload

**Files:**
- Create: `shared/autoloads/GameManager.gd`

- [ ] **Step 1: Create GameManager**

  Create `shared/autoloads/GameManager.gd`:
  ```gdscript
  extends Node

  signal scene_changed(scene_name: String)

  var current_game: String = ""
  var current_level: String = ""
  var _pending_score: int = 0
  var _pending_level: String = ""

  func go_to_hub() -> void:
      get_tree().change_scene_to_file("res://hub/Hub.tscn")
      scene_changed.emit("hub")

  func go_to_level_select(game: String) -> void:
      current_game = game
      get_tree().change_scene_to_file("res://games/%s/LevelSelect.tscn" % game)
      scene_changed.emit("level_select")

  func start_game(game: String, level: String) -> void:
      current_game = game
      current_level = level
      get_tree().change_scene_to_file("res://games/%s/PaddleBall.tscn" % game)
      scene_changed.emit(game)

  func go_to_score_screen(score: int, level: String) -> void:
      _pending_score = score
      _pending_level = level
      get_tree().change_scene_to_file(
          "res://games/%s/ScoreScreen.tscn" % current_game
      )
      scene_changed.emit("score_screen")

  func get_pending_result() -> Dictionary:
      return {"score": _pending_score, "level": _pending_level}
  ```

- [ ] **Step 2: Register as autoload**

  **Project → Project Settings → Autoload** → add `shared/autoloads/GameManager.gd` as `GameManager`.

- [ ] **Step 3: Commit**

  ```bash
  git add shared/autoloads/GameManager.gd project.godot
  git commit -m "feat(game): add GameManager autoload"
  ```

---

## Task 4: AudioManager Autoload

**Files:**
- Create: `shared/autoloads/AudioManager.gd`

- [ ] **Step 1: Set up audio buses in Godot editor**

  **Project → Project Settings → Audio** → add two extra buses:
  - Bus 2: name `Music`, parent bus `Master`
  - Bus 3: name `SFX`, parent bus `Master`
  
  Save the bus layout.

- [ ] **Step 2: Create AudioManager**

  Create `shared/autoloads/AudioManager.gd`:
  ```gdscript
  extends Node

  var _music_player: AudioStreamPlayer
  var _sfx_player: AudioStreamPlayer
  var _music_tracks: Dictionary = {}
  var _sfx_sounds: Dictionary = {}

  func _ready() -> void:
      _music_player = AudioStreamPlayer.new()
      _music_player.bus = "Music"
      add_child(_music_player)

      _sfx_player = AudioStreamPlayer.new()
      _sfx_player.bus = "SFX"
      add_child(_sfx_player)

      _apply_volume_settings()

  func register_music(track_name: String, stream: AudioStream) -> void:
      _music_tracks[track_name] = stream

  func register_sfx(sound_name: String, stream: AudioStream) -> void:
      _sfx_sounds[sound_name] = stream

  func play_music(track_name: String) -> void:
      if not _music_tracks.has(track_name):
          return
      if _music_player.stream == _music_tracks[track_name] and _music_player.playing:
          return
      _music_player.stream = _music_tracks[track_name]
      _music_player.play()

  func stop_music() -> void:
      _music_player.stop()

  func play_sfx(sound_name: String) -> void:
      if not _sfx_sounds.has(sound_name):
          return
      var player = AudioStreamPlayer.new()
      player.stream = _sfx_sounds[sound_name]
      player.bus = "SFX"
      player.autoplay = true
      add_child(player)
      player.finished.connect(player.queue_free)

  func _apply_volume_settings() -> void:
      var master_vol: float = SaveManager.get_setting("master_volume", 1.0)
      var music_vol: float = SaveManager.get_setting("music_volume", 0.8)
      var sfx_vol: float = SaveManager.get_setting("sfx_volume", 1.0)
      AudioServer.set_bus_volume_db(
          AudioServer.get_bus_index("Master"), linear_to_db(master_vol)
      )
      AudioServer.set_bus_volume_db(
          AudioServer.get_bus_index("Music"), linear_to_db(music_vol)
      )
      AudioServer.set_bus_volume_db(
          AudioServer.get_bus_index("SFX"), linear_to_db(sfx_vol)
      )
  ```

- [ ] **Step 3: Register as autoload**

  **Project → Project Settings → Autoload** → add `shared/autoloads/AudioManager.gd` as `AudioManager`. Ensure load order: SaveManager → GameManager → AudioManager.

- [ ] **Step 4: Commit**

  ```bash
  git add shared/autoloads/AudioManager.gd project.godot
  git commit -m "feat(audio): add AudioManager autoload with Music/SFX buses"
  ```

---

## Task 5: LevelConfig Data Class

**Files:**
- Create: `games/paddleball/LevelConfig.gd`
- Create: `tests/test_level_config.gd`

- [ ] **Step 1: Write failing tests**

  Create `tests/test_level_config.gd`:
  ```gdscript
  extends GutTest

  func test_get_all_levels_returns_five() -> void:
      assert_eq(LevelConfig.get_all_levels().size(), 5)

  func test_rookie_has_no_targets() -> void:
      assert_eq(LevelConfig.rookie().target_count, 0)

  func test_legend_has_moving_walls() -> void:
      assert_true(LevelConfig.legend().moving_walls)

  func test_cadet_has_static_targets() -> void:
      var c = LevelConfig.cadet()
      assert_gt(c.target_count, 0)
      assert_false(c.targets_move)

  func test_pilot_targets_move() -> void:
      assert_true(LevelConfig.pilot().targets_move)

  func test_ace_has_multi_ball() -> void:
      assert_true(LevelConfig.ace().multi_ball)

  func test_endless_config_base_speed_is_max() -> void:
      var e = LevelConfig.endless()
      assert_gt(e.ball_speed, LevelConfig.legend().ball_speed)
  ```

- [ ] **Step 2: Run to verify failure**

  ```bash
  godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_level_config.gd
  # Expected: FAIL — LevelConfig not found
  ```

- [ ] **Step 3: Implement LevelConfig**

  Create `games/paddleball/LevelConfig.gd`:
  ```gdscript
  class_name LevelConfig
  extends RefCounted

  var name: String
  var id: String
  var ball_speed: float
  var paddle_width: float
  var target_count: int
  var targets_move: bool
  var multi_ball: bool
  var moving_walls: bool
  var obstacles: bool
  var arena_theme: String
  var lives: int
  var is_endless: bool = false

  static func get_all_levels() -> Array:
      return [rookie(), cadet(), pilot(), ace(), legend()]

  static func rookie() -> LevelConfig:
      var c := LevelConfig.new()
      c.name = "Rookie"; c.id = "rookie"
      c.ball_speed = 8.0; c.paddle_width = 2.0
      c.target_count = 0; c.targets_move = false
      c.multi_ball = false; c.moving_walls = false
      c.obstacles = false; c.arena_theme = "neon_cyber"; c.lives = 5
      return c

  static func cadet() -> LevelConfig:
      var c := LevelConfig.new()
      c.name = "Cadet"; c.id = "cadet"
      c.ball_speed = 12.0; c.paddle_width = 1.5
      c.target_count = 6; c.targets_move = false
      c.multi_ball = false; c.moving_walls = false
      c.obstacles = false; c.arena_theme = "neon_cyber"; c.lives = 4
      return c

  static func pilot() -> LevelConfig:
      var c := LevelConfig.new()
      c.name = "Pilot"; c.id = "pilot"
      c.ball_speed = 16.0; c.paddle_width = 1.5
      c.target_count = 8; c.targets_move = true
      c.multi_ball = false; c.moving_walls = false
      c.obstacles = false; c.arena_theme = "space_station"; c.lives = 3
      return c

  static func ace() -> LevelConfig:
      var c := LevelConfig.new()
      c.name = "Ace"; c.id = "ace"
      c.ball_speed = 20.0; c.paddle_width = 1.0
      c.target_count = 10; c.targets_move = true
      c.multi_ball = true; c.moving_walls = false
      c.obstacles = true; c.arena_theme = "space_station"; c.lives = 3
      return c

  static func legend() -> LevelConfig:
      var c := LevelConfig.new()
      c.name = "Legend"; c.id = "legend"
      c.ball_speed = 25.0; c.paddle_width = 1.0
      c.target_count = 12; c.targets_move = true
      c.multi_ball = true; c.moving_walls = true
      c.obstacles = true; c.arena_theme = "reactor_core"; c.lives = 2
      return c

  static func endless() -> LevelConfig:
      var c := LevelConfig.new()
      c.name = "Endless"; c.id = "endless"
      c.ball_speed = 30.0; c.paddle_width = 1.0
      c.target_count = 0; c.targets_move = true
      c.multi_ball = true; c.moving_walls = true
      c.obstacles = true; c.arena_theme = "reactor_core"
      c.lives = 3; c.is_endless = true
      return c
  ```

- [ ] **Step 4: Run tests to verify they pass**

  ```bash
  godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_level_config.gd
  # Expected: 7 tests passed, 0 failed
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add games/paddleball/LevelConfig.gd tests/test_level_config.gd
  git commit -m "feat(paddleball): add LevelConfig with all 5 levels + endless"
  ```

---

## Task 6: ComboSystem Logic Class

**Files:**
- Create: `games/paddleball/ComboSystem.gd`
- Create: `tests/test_combo_system.gd`

- [ ] **Step 1: Write failing tests**

  Create `tests/test_combo_system.gd`:
  ```gdscript
  extends GutTest

  var combo: ComboSystem

  func before_each() -> void:
      combo = ComboSystem.new()

  func test_initial_multiplier_is_one() -> void:
      assert_eq(combo.multiplier, 1)

  func test_three_hits_gives_x3() -> void:
      combo.record_hit()
      combo.record_hit()
      combo.record_hit()
      assert_eq(combo.multiplier, 3)

  func test_six_hits_gives_x6() -> void:
      for i in 6:
          combo.record_hit()
      assert_eq(combo.multiplier, 6)

  func test_ten_hits_gives_x10() -> void:
      for i in 10:
          combo.record_hit()
      assert_eq(combo.multiplier, 10)

  func test_reset_sets_multiplier_to_one() -> void:
      for i in 6:
          combo.record_hit()
      combo.reset()
      assert_eq(combo.multiplier, 1)

  func test_calculate_score_applies_multiplier() -> void:
      for i in 3:
          combo.record_hit()
      assert_eq(combo.calculate_score(100), 300)

  func test_ultra_signal_fires_at_ten_hits() -> void:
      watch_signals(combo)
      for i in 10:
          combo.record_hit()
      assert_signal_emitted(combo, "ultra_triggered")

  func test_ultra_signal_not_fired_at_nine_hits() -> void:
      watch_signals(combo)
      for i in 9:
          combo.record_hit()
      assert_signal_not_emitted(combo, "ultra_triggered")
  ```

- [ ] **Step 2: Run to verify failure**

  ```bash
  godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_combo_system.gd
  # Expected: FAIL — ComboSystem not found
  ```

- [ ] **Step 3: Implement ComboSystem**

  Create `games/paddleball/ComboSystem.gd`:
  ```gdscript
  class_name ComboSystem
  extends RefCounted

  signal combo_changed(multiplier: int)
  signal ultra_triggered

  const ULTRA_THRESHOLD: int = 10

  var multiplier: int = 1
  var hit_count: int = 0
  var _ultra_fired: bool = false

  func record_hit() -> void:
      hit_count += 1
      _update_multiplier()
      if hit_count >= ULTRA_THRESHOLD and not _ultra_fired:
          _ultra_fired = true
          ultra_triggered.emit()

  func reset() -> void:
      hit_count = 0
      _ultra_fired = false
      var old := multiplier
      multiplier = 1
      if old != multiplier:
          combo_changed.emit(multiplier)

  func calculate_score(base_points: int) -> int:
      return base_points * multiplier

  func _update_multiplier() -> void:
      var old := multiplier
      if hit_count >= 10:
          multiplier = 10
      elif hit_count >= 6:
          multiplier = 6
      elif hit_count >= 3:
          multiplier = 3
      else:
          multiplier = 1
      if multiplier != old:
          combo_changed.emit(multiplier)
  ```

- [ ] **Step 4: Run tests to verify they pass**

  ```bash
  godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_combo_system.gd
  # Expected: 8 tests passed, 0 failed
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add games/paddleball/ComboSystem.gd tests/test_combo_system.gd
  git commit -m "feat(paddleball): add ComboSystem with multiplier and ULTRA trigger"
  ```

---

## Task 7: Hub Launcher Scene

**Files:**
- Create: `hub/Hub.tscn` (Godot editor)
- Create: `hub/Hub.gd`
- Create: `hub/GameCard.tscn` (Godot editor)
- Create: `hub/GameCard.gd`

- [ ] **Step 1: Create GameCard scene in editor**

  In Godot FileSystem: right-click `hub/` → **New Scene**. Name: `GameCard.tscn`.
  
  Node tree:
  ```
  PanelContainer (root) — rename to GameCard
  └── VBoxContainer
      ├── Label (name: GameTitle)
      ├── Label (name: BestScore)
      └── Button (name: PlayButton, text: "PLAY")
  ```

- [ ] **Step 2: Create GameCard script**

  Attach a new script to the `GameCard` root node. Save as `hub/GameCard.gd`:
  ```gdscript
  extends PanelContainer

  signal play_pressed(game_id: String)

  @export var game_id: String = ""
  @export var game_display_name: String = ""

  @onready var _title: Label = $VBoxContainer/GameTitle
  @onready var _score: Label = $VBoxContainer/BestScore
  @onready var _play_btn: Button = $VBoxContainer/PlayButton

  func _ready() -> void:
      _play_btn.pressed.connect(_on_play_pressed)

  func setup(id: String, display_name: String, locked: bool) -> void:
      game_id = id
      game_display_name = display_name
      _title.text = display_name
      if locked:
          _score.text = "🔒 LOCKED"
          _play_btn.disabled = true
          modulate = Color(0.4, 0.4, 0.4, 1.0)
      else:
          var best := SaveManager.get_high_score(id, "rookie")
          _score.text = "BEST: %d" % best
          _play_btn.disabled = false
          modulate = Color.WHITE

  func _on_play_pressed() -> void:
      play_pressed.emit(game_id)
  ```

- [ ] **Step 3: Create Hub scene in editor**

  Right-click `hub/` → **New Scene**. Name: `Hub.tscn`.
  
  Node tree:
  ```
  Control (root) — rename to Hub, set anchors to Full Rect
  ├── ColorRect (name: Background, color #070714, Full Rect)
  ├── Label (name: Title, text: "ARCADE NEXUS", anchor top-center)
  └── ScrollContainer (name: CardGrid, center of screen)
      └── GridContainer (name: Grid, columns: 3)
  ```

- [ ] **Step 4: Create Hub script**

  Attach script to Hub root. Save as `hub/Hub.gd`:
  ```gdscript
  extends Control

  const GAME_CARD = preload("res://hub/GameCard.tscn")

  # Registry of all games. Add new games here as the arcade grows.
  const GAMES: Array = [
      {"id": "paddleball", "name": "PADDLE BALL", "locked": false},
      {"id": "game2", "name": "COMING SOON", "locked": true},
      {"id": "game3", "name": "COMING SOON", "locked": true},
  ]

  @onready var _grid: GridContainer = $ScrollContainer/Grid

  func _ready() -> void:
      for game_data in GAMES:
          var card: PanelContainer = GAME_CARD.instantiate()
          _grid.add_child(card)
          card.setup(game_data["id"], game_data["name"], game_data["locked"])
          card.play_pressed.connect(_on_game_selected)

  func _on_game_selected(game_id: String) -> void:
      GameManager.go_to_level_select(game_id)
  ```

- [ ] **Step 5: Verify in editor**

  Run the Hub scene directly (F6 with Hub.tscn open). Verify:
  - Three game cards appear
  - "PADDLE BALL" card has PLAY button enabled
  - Other two cards are dimmed and disabled
  - Clicking PLAY on paddleball triggers scene switch (will error since LevelSelect doesn't exist yet — that's fine)

- [ ] **Step 6: Commit**

  ```bash
  git add hub/
  git commit -m "feat(hub): add Hub launcher with GameCard grid"
  ```

---

## Task 8: Main Boot Scene + Neon Theme

**Files:**
- Create: `Main.tscn` (Godot editor)
- Create: `Main.gd`
- Create: `shared/theme.tres` (Godot editor)

- [ ] **Step 1: Create neon arcade UI theme**

  In Godot FileSystem: right-click `shared/` → **New Resource** → select `Theme` → save as `theme.tres`.
  
  Open theme.tres. Set these overrides (click the type you want to override, e.g., Button):
  
  | Element | Property | Value |
  |---|---|---|
  | Panel | BG Color | `#0d0d1a` |
  | Button (Normal) | BG Color | `#1a1a2e` |
  | Button (Hover) | BG Color | `#2d2d5a` |
  | Button (Pressed) | BG Color | `#7c83ff` |
  | Label | Font Color | `#e0e0ff` |
  
  In **Project Settings → GUI → Theme → Custom**, set the path to `res://shared/theme.tres`.

- [ ] **Step 2: Create Main boot scene**

  Right-click root of FileSystem → **New Scene**. Name: `Main.tscn`.
  
  Node tree:
  ```
  Node (root) — rename to Main
  ```
  
  Attach script. Save as `Main.gd`:
  ```gdscript
  extends Node

  func _ready() -> void:
      # Brief boot delay then go to hub
      await get_tree().create_timer(0.1).timeout
      GameManager.go_to_hub()
  ```

- [ ] **Step 3: Set Main.tscn as the application start scene**

  **Project → Project Settings → Application → Run → Main Scene** → set to `res://Main.tscn`.

- [ ] **Step 4: Run the project (F5)**

  Expected: hub appears with 3 game cards on dark background.

- [ ] **Step 5: Commit**

  ```bash
  git add Main.tscn Main.gd shared/theme.tres project.godot
  git commit -m "feat(hub): add boot scene and neon UI theme"
  ```

---

## Task 9: Arena 3D Scene

**Files:**
- Create: `games/paddleball/Arena.tscn` (Godot editor)
- Create: `games/paddleball/Arena.gd`

- [ ] **Step 1: Create Arena scene in editor**

  New scene. Name: `Arena.tscn`.
  
  Node tree:
  ```
  Node3D (root) — rename to Arena
  ├── WorldEnvironment (name: Environment)
  ├── DirectionalLight3D (name: SunLight)
  ├── Camera3D (name: Camera, position: (0, 5, 12), rotation: (-15°, 0, 0))
  ├── MeshInstance3D (name: Floor, mesh: BoxMesh 12×0.2×20)
  ├── MeshInstance3D (name: Ceiling, mesh: BoxMesh 12×0.2×20, y=8)
  ├── MeshInstance3D (name: WallLeft, mesh: BoxMesh 0.2×8×20, x=-6)
  ├── MeshInstance3D (name: WallRight, mesh: BoxMesh 0.2×8×20, x=6)
  ├── MeshInstance3D (name: WallBack, mesh: BoxMesh 12×8×0.2, z=-10)
  ├── StaticBody3D (name: FloorCollider)
  │   └── CollisionShape3D (shape: BoxShape 12×0.2×20)
  ├── StaticBody3D (name: CeilingCollider)
  │   └── CollisionShape3D (shape: BoxShape 12×0.2×20, y=8)
  ├── StaticBody3D (name: WallLeftCollider)
  │   └── CollisionShape3D (shape: BoxShape 0.2×8×20, x=-6)
  ├── StaticBody3D (name: WallRightCollider)
  │   └── CollisionShape3D (shape: BoxShape 0.2×8×20, x=6)
  ├── StaticBody3D (name: WallBackCollider)
  │   └── CollisionShape3D (shape: BoxShape 12×8×0.2, z=-10)
  └── Node3D (name: TargetSpawnPoints)
  ```

- [ ] **Step 2: Configure WorldEnvironment**

  Select `Environment` node → Inspector → create new `Environment` resource. Set:
  - Background Mode: `Color` → color `#030308`
  - Glow: enabled, intensity `0.8`, bloom `0.5`
  - SSAO: enabled, radius `1.0`
  - Ambient Light: color `#1a1a4a`, energy `0.3`

- [ ] **Step 3: Apply neon emissive material to walls**

  For each wall and floor MeshInstance3D, create a new `StandardMaterial3D`:
  - **Floor**: Albedo `#0a0a1a`, Metallic `0.8`, Roughness `0.1`, Emission enabled, color `#1a1a4a`, energy `0.5`
  - **Walls**: Albedo `#050510`, Emission enabled, color `#7c83ff`, energy `0.3`
  - **Ceiling**: same as walls

- [ ] **Step 4: Create Arena script**

  Attach script to Arena root. Save as `games/paddleball/Arena.gd`:
  ```gdscript
  extends Node3D

  enum Theme { NEON_CYBER, SPACE_STATION, REACTOR_CORE }

  @onready var _env: WorldEnvironment = $Environment

  func update_camera_fov(ball_speed: float, max_speed: float) -> void:
      # Dynamic FOV: 70° at rest, up to 90° at max speed
      _camera.fov = lerpf(70.0, 90.0, ball_speed / max_speed)

  func apply_theme(theme: Theme) -> void:
      match theme:
          Theme.NEON_CYBER:
              _env.environment.ambient_light_color = Color(0.1, 0.1, 0.3)
              _env.environment.glow_intensity = 0.8
          Theme.SPACE_STATION:
              _env.environment.ambient_light_color = Color(0.05, 0.05, 0.15)
              _env.environment.glow_intensity = 0.6
          Theme.REACTOR_CORE:
              _env.environment.ambient_light_color = Color(0.3, 0.1, 0.0)
              _env.environment.glow_intensity = 1.2

  func get_theme_from_string(theme_str: String) -> Theme:
      match theme_str:
          "space_station": return Theme.SPACE_STATION
          "reactor_core": return Theme.REACTOR_CORE
          _: return Theme.NEON_CYBER
  ```

- [ ] **Step 5: Run the Arena scene (F6)**

  Expected: dark enclosed 3D room with glowing neon walls and bloom effect visible.

- [ ] **Step 6: Commit**

  ```bash
  git add games/paddleball/Arena.tscn games/paddleball/Arena.gd
  git commit -m "feat(paddleball): add Arena 3D scene with neon materials and WorldEnvironment"
  ```

---

## Task 10: Paddle Scene

**Files:**
- Create: `games/paddleball/Paddle.tscn` (Godot editor)
- Create: `games/paddleball/Paddle.gd`

- [ ] **Step 1: Create Paddle scene in editor**

  New scene. Name: `Paddle.tscn`.
  
  Node tree:
  ```
  StaticBody3D (root) — rename to Paddle
  ├── MeshInstance3D (name: PaddleMesh, mesh: BoxMesh 2.0×0.15×0.4)
  ├── CollisionShape3D (shape: BoxShape 2.0×0.15×0.4)
  └── GPUParticles3D (name: HitSparks, emitting: false)
  ```
  
  On `PaddleMesh`, create a `StandardMaterial3D`:
  - Albedo: `#3a3aff`
  - Emission enabled, color `#7c83ff`, energy `2.0`
  - Metallic: `0.9`, Roughness: `0.1`

- [ ] **Step 2: Create Paddle script**

  Attach script to Paddle root. Save as `games/paddleball/Paddle.gd`:
  ```gdscript
  extends StaticBody3D

  signal ball_hit(hit_normal: Vector3, hit_position: Vector3)

  @export var move_speed: float = 12.0
  @export var width: float = 2.0

  const ARENA_HALF_WIDTH: float = 5.5
  const PADDLE_Z: float = 9.0

  @onready var _mesh: MeshInstance3D = $PaddleMesh
  @onready var _sparks: GPUParticles3D = $HitSparks

  var _velocity: Vector3 = Vector3.ZERO

  func _ready() -> void:
      position.z = PADDLE_Z
      position.y = 0.3
      _update_width()

  func _physics_process(delta: float) -> void:
      var input_dir := 0.0
      if Input.is_action_pressed("ui_left"):
          input_dir = -1.0
      if Input.is_action_pressed("ui_right"):
          input_dir = 1.0

      # Mouse delta
      var mouse_rel := Input.get_last_mouse_velocity().x * 0.002
      input_dir += mouse_rel

      position.x = clamp(
          position.x + input_dir * move_speed * delta,
          -ARENA_HALF_WIDTH + width * 0.5,
          ARENA_HALF_WIDTH - width * 0.5
      )

  func set_width(new_width: float) -> void:
      width = new_width
      _update_width()

  func emit_hit_sparks() -> void:
      _sparks.restart()
      _sparks.emitting = true

  func get_spin_from_hit(hit_x: float) -> float:
      # Returns -1..1 based on where ball hits relative to paddle center
      return clamp((hit_x - position.x) / (width * 0.5), -1.0, 1.0)

  func _update_width() -> void:
      var box_shape := BoxShape3D.new()
      box_shape.size = Vector3(width, 0.15, 0.4)
      $CollisionShape3D.shape = box_shape
      (_mesh.mesh as BoxMesh).size = Vector3(width, 0.15, 0.4)
  ```

- [ ] **Step 3: Configure HitSparks particles**

  Select `HitSparks` node → Inspector:
  - Amount: 30
  - One Shot: true
  - Lifetime: 0.4
  - Create `ParticleProcessMaterial`: initial velocity min `2.0`, max `5.0`, color `#7c83ff`

- [ ] **Step 4: Run Arena scene with Paddle**

  Add a Paddle instance to Arena.tscn temporarily. Run (F6). Verify paddle moves left/right with arrow keys, stays within arena walls.

- [ ] **Step 5: Remove temporary Paddle from Arena**

  The PaddleBall game controller (Task 12) will instantiate it. Remove from Arena.tscn now.

- [ ] **Step 6: Commit**

  ```bash
  git add games/paddleball/Paddle.tscn games/paddleball/Paddle.gd
  git commit -m "feat(paddleball): add Paddle scene with mouse/keyboard movement and spin"
  ```

---

## Task 11: Ball Scene + Physics

**Files:**
- Create: `games/paddleball/Ball.tscn` (Godot editor)
- Create: `games/paddleball/Ball.gd`

- [ ] **Step 1: Create Ball scene in editor**

  New scene. Name: `Ball.tscn`.
  
  Node tree:
  ```
  RigidBody3D (root) — rename to Ball
  ├── MeshInstance3D (name: BallMesh, mesh: SphereMesh radius 0.2)
  ├── CollisionShape3D (shape: SphereShape radius 0.2)
  ├── GPUParticles3D (name: Trail, emitting: true)
  ├── GPUParticles3D (name: ImpactSparks, emitting: false, one_shot: true)
  └── OmniLight3D (name: BallLight, range: 3.0, energy: 2.0, color: #7cff9e)
  ```
  
  `BallMesh` material `StandardMaterial3D`:
  - Albedo: `#aaffaa`
  - Emission: enabled, color `#7cff9e`, energy `3.0`

- [ ] **Step 2: Create Ball script**

  Attach script to Ball root. Save as `games/paddleball/Ball.gd`:
  ```gdscript
  extends RigidBody3D

  signal hit_paddle(hit_position: Vector3)
  signal hit_wall
  signal fell_out

  @export var base_speed: float = 10.0
  @export var speed_increment: float = 0.3

  const MAX_SPEED: float = 40.0
  const DEATH_Z: float = 11.0

  @onready var _trail: GPUParticles3D = $Trail
  @onready var _sparks: GPUParticles3D = $ImpactSparks
  @onready var _light: OmniLight3D = $BallLight

  var _current_speed: float = 0.0
  var _spin_factor: float = 0.0

  func _ready() -> void:
      gravity_scale = 0.0
      contact_monitor = true
      max_contacts_reported = 4
      body_entered.connect(_on_body_entered)

  func launch(speed: float) -> void:
      _current_speed = speed
      linear_velocity = Vector3(0.3, 0.5, -1.0).normalized() * _current_speed

  func apply_spin(spin: float) -> void:
      _spin_factor = spin
      var vel := linear_velocity
      vel.x += spin * 3.0
      linear_velocity = vel.normalized() * _current_speed

  func accelerate() -> void:
      _current_speed = minf(_current_speed + speed_increment, MAX_SPEED)
      linear_velocity = linear_velocity.normalized() * _current_speed
      _update_trail_speed()

  func _physics_process(_delta: float) -> void:
      if position.z > DEATH_Z:
          fell_out.emit()

      # Keep speed constant (physics may drift)
      if linear_velocity.length() > 0.1:
          linear_velocity = linear_velocity.normalized() * _current_speed

  func _on_body_entered(body: Node) -> void:
      _sparks.restart()
      _sparks.emitting = true
      if body.is_in_group("paddle"):
          hit_paddle.emit(position)
      else:
          hit_wall.emit()

  func _update_trail_speed() -> void:
      var ratio := _current_speed / MAX_SPEED
      _trail.speed_scale = 1.0 + ratio * 2.0
      _light.energy = 2.0 + ratio * 3.0
  ```

- [ ] **Step 3: Configure Trail particles**

  Select `Trail` node:
  - Amount: 50, Lifetime: 0.3
  - `ParticleProcessMaterial`: direction `(0,0,1)`, spread `5°`, initial velocity `1.0`–`2.0`, scale min `0.05`, max `0.15`, color `#7cff9e` → transparent gradient

- [ ] **Step 4: Add Ball to Arena temporarily and test**

  Add Ball to Arena.tscn. In `Arena.gd` `_ready()`, call `$Ball.launch(10.0)`. Run (F6). Verify:
  - Ball moves and bounces off walls
  - Trail particles follow
  - Ball glow light moves with it

  Remove the temporary Ball from Arena after verification.

- [ ] **Step 5: Commit**

  ```bash
  git add games/paddleball/Ball.tscn games/paddleball/Ball.gd
  git commit -m "feat(paddleball): add Ball scene with RigidBody physics and trail particles"
  ```

---

## Task 12: Target Scene

**Files:**
- Create: `games/paddleball/Target.tscn` (Godot editor)
- Create: `games/paddleball/Target.gd`

- [ ] **Step 1: Create Target scene in editor**

  New scene. Name: `Target.tscn`.
  
  Node tree:
  ```
  Area3D (root) — rename to Target
  ├── MeshInstance3D (name: TargetMesh, mesh: BoxMesh 0.8×0.3×0.3)
  ├── CollisionShape3D (shape: BoxShape 0.8×0.3×0.3)
  ├── OmniLight3D (name: TargetLight, range: 2.0, energy: 1.5)
  └── GPUParticles3D (name: DestroyEffect, emitting: false, one_shot: true)
  ```

- [ ] **Step 2: Create Target script**

  Attach script to Target root. Save as `games/paddleball/Target.gd`:
  ```gdscript
  extends Area3D

  signal destroyed(points: int)

  enum PointValue { LOW = 100, MED = 300, HIGH = 500 }
  enum Color { BLUE, ORANGE, RED }

  @export var point_value: int = PointValue.LOW
  @export var moves: bool = false
  @export var move_speed: float = 1.5
  @export var move_range: float = 1.5

  @onready var _mesh: MeshInstance3D = $TargetMesh
  @onready var _light: OmniLight3D = $TargetLight
  @onready var _destroy_fx: GPUParticles3D = $DestroyEffect

  var _origin: Vector3
  var _time: float = 0.0

  func _ready() -> void:
      _origin = position
      body_entered.connect(_on_body_entered)
      _apply_color()

  func setup(value: int, should_move: bool) -> void:
      point_value = value
      moves = should_move
      _apply_color()

  func _process(delta: float) -> void:
      if not moves:
          return
      _time += delta
      position.x = _origin.x + sin(_time * move_speed) * move_range

  func _apply_color() -> void:
      var mat := StandardMaterial3D.new()
      mat.emission_enabled = true
      match point_value:
          PointValue.LOW:
              mat.albedo_color = Color(0.2, 0.4, 1.0)
              mat.emission = Color(0.2, 0.4, 1.0)
              _light.light_color = Color(0.2, 0.4, 1.0)
          PointValue.MED:
              mat.albedo_color = Color(1.0, 0.5, 0.1)
              mat.emission = Color(1.0, 0.5, 0.1)
              _light.light_color = Color(1.0, 0.5, 0.1)
          PointValue.HIGH:
              mat.albedo_color = Color(1.0, 0.2, 0.2)
              mat.emission = Color(1.0, 0.2, 0.2)
              _light.light_color = Color(1.0, 0.2, 0.2)
      mat.emission_energy_multiplier = 2.0
      _mesh.material_override = mat

  func _on_body_entered(body: Node) -> void:
      if not body.is_in_group("ball"):
          return
      _destroy_fx.restart()
      _destroy_fx.emitting = true
      destroyed.emit(point_value)
      # Hide mesh immediately, free after particles finish
      _mesh.visible = false
      $CollisionShape3D.disabled = true
      await get_tree().create_timer(0.5).timeout
      queue_free()
  ```

- [ ] **Step 3: Configure DestroyEffect particles**

  Select `DestroyEffect`: Amount `40`, Lifetime `0.5`, One Shot `true`.
  `ParticleProcessMaterial`: initial velocity `3.0`–`8.0`, gravity `(0,-2,0)`, scale `0.1`–`0.3`.

- [ ] **Step 4: Commit**

  ```bash
  git add games/paddleball/Target.tscn games/paddleball/Target.gd
  git commit -m "feat(paddleball): add Target scene with color-coded point values and destroy FX"
  ```

---

## Task 13: HUD Overlay

**Files:**
- Create: `games/paddleball/HUD.tscn` (Godot editor)
- Create: `games/paddleball/HUD.gd`

- [ ] **Step 1: Create HUD scene in editor**

  New scene. Name: `HUD.tscn`.
  
  Node tree:
  ```
  CanvasLayer (root) — rename to HUD
  ├── Label (name: ScoreLabel, anchor: top-left, offset: 20,20)
  ├── Label (name: LevelLabel, anchor: top-center)
  ├── HBoxContainer (name: LivesContainer, anchor: top-right)
  ├── Label (name: ComboLabel, anchor: center-right, offset: -40,0)
  └── Label (name: FlashText, anchor: center, visible: false)
  ```

- [ ] **Step 2: Create HUD script**

  Attach script. Save as `games/paddleball/HUD.gd`:
  ```gdscript
  extends CanvasLayer

  @onready var _score: Label = $ScoreLabel
  @onready var _level: Label = $LevelLabel
  @onready var _lives_container: HBoxContainer = $LivesContainer
  @onready var _combo: Label = $ComboLabel
  @onready var _flash: Label = $FlashText

  func set_score(value: int) -> void:
      _score.text = "SCORE: %d" % value

  func set_level(name: String) -> void:
      _level.text = name

  func set_lives(current: int, max_lives: int) -> void:
      for child in _lives_container.get_children():
          child.queue_free()
      for i in max_lives:
          var heart := Label.new()
          heart.text = "❤️" if i < current else "🖤"
          _lives_container.add_child(heart)

  func set_combo(multiplier: int) -> void:
      if multiplier <= 1:
          _combo.text = ""
          _combo.modulate = Color.WHITE
      else:
          _combo.text = "x%d" % multiplier
          match multiplier:
              3: _combo.modulate = Color(1.0, 0.85, 0.0)   # gold at x3
              6: _combo.modulate = Color(1.0, 0.5, 0.0)    # orange at x6
              10: _combo.modulate = Color(1.0, 0.2, 0.0)   # red at x10 ULTRA
              _: _combo.modulate = Color(1.0, 0.85, 0.0)

  func show_flash(text: String, duration: float = 1.5) -> void:
      _flash.text = text
      _flash.visible = true
      await get_tree().create_timer(duration).timeout
      _flash.visible = false
  ```

- [ ] **Step 3: Style flash text**

  Select `FlashText` in editor → Inspector:
  - Font Size: 48
  - Horizontal Alignment: Center
  - Modulate: `#f59e0b`
  - Add `LabelSettings` → Shadow enabled, size 4

- [ ] **Step 4: Commit**

  ```bash
  git add games/paddleball/HUD.tscn games/paddleball/HUD.gd
  git commit -m "feat(paddleball): add HUD overlay with score, lives, combo, flash text"
  ```

---

## Task 14: PaddleBall Game Controller

**Files:**
- Create: `games/paddleball/PaddleBall.tscn` (Godot editor)
- Create: `games/paddleball/PaddleBall.gd`

- [ ] **Step 1: Create PaddleBall scene in editor**

  New scene. Name: `PaddleBall.tscn`.
  
  Node tree:
  ```
  Node3D (root) — rename to PaddleBall
  ├── Arena (instance of Arena.tscn)
  ├── Paddle (instance of Paddle.tscn) — add to group "paddle"
  ├── Ball (instance of Ball.tscn) — add to group "ball"
  ├── HUD (instance of HUD.tscn)
  └── Node3D (name: TargetsRoot)
  ```

- [ ] **Step 2: Create PaddleBall script**

  Attach script. Save as `games/paddleball/PaddleBall.gd`:
  ```gdscript
  extends Node3D

  const TARGET_SCENE = preload("res://games/paddleball/Target.tscn")
  const BALL_SCENE = preload("res://games/paddleball/Ball.tscn")

  @onready var _arena: Node3D = $Arena
  @onready var _paddle: StaticBody3D = $Paddle
  @onready var _hud: CanvasLayer = $HUD
  @onready var _targets_root: Node3D = $TargetsRoot

  var _config: LevelConfig
  var _combo: ComboSystem
  var _score: int = 0
  var _lives: int = 3
  var _balls: Array = []
  var _targets_remaining: int = 0
  var _game_active: bool = false
  var _elapsed: float = 0.0
  const SPEED_TICK: float = 5.0  # seconds between auto-acceleration

  func _ready() -> void:
      _config = _get_level_config()
      _combo = ComboSystem.new()
      _combo.combo_changed.connect(_on_combo_changed)
      _combo.ultra_triggered.connect(_on_ultra_triggered)

      _lives = _config.lives
      _paddle.set_width(_config.paddle_width)
      _arena.apply_theme(_arena.get_theme_from_string(_config.arena_theme))

      _hud.set_score(0)
      _hud.set_level(_config.name)
      _hud.set_lives(_lives, _config.lives)
      _hud.set_combo(1)

      _spawn_targets()
      _spawn_ball()
      _game_active = true

  func _physics_process(delta: float) -> void:
      if not _game_active:
          return
      _elapsed += delta
      if int(_elapsed) % int(SPEED_TICK) == 0 and fmod(_elapsed, SPEED_TICK) < delta:
          for ball in _balls:
              if is_instance_valid(ball):
                  ball.accelerate()

  func _get_level_config() -> LevelConfig:
      var level_id := GameManager.current_level
      match level_id:
          "cadet": return LevelConfig.cadet()
          "pilot": return LevelConfig.pilot()
          "ace": return LevelConfig.ace()
          "legend": return LevelConfig.legend()
          "endless": return LevelConfig.endless()
          _: return LevelConfig.rookie()

  func _spawn_ball() -> void:
      var ball: RigidBody3D = BALL_SCENE.instantiate()
      add_child(ball)
      ball.position = Vector3(0, 3, 0)
      ball.hit_paddle.connect(_on_ball_hit_paddle.bind(ball))
      ball.hit_wall.connect(_on_ball_hit_wall)
      ball.fell_out.connect(_on_ball_fell_out.bind(ball))
      ball.launch(_config.ball_speed)
      _balls.append(ball)

  func _spawn_targets() -> void:
      _targets_remaining = _config.target_count
      if _config.target_count == 0:
          return
      var point_values := [100, 300, 500]
      for i in _config.target_count:
          var target: Area3D = TARGET_SCENE.instantiate()
          _targets_root.add_child(target)
          var col := i % 3
          var row := i / 3
          target.position = Vector3(-4.0 + col * 4.0, 2.0 + row * 1.5, -5.0 - row * 1.0)
          target.setup(point_values[col], _config.targets_move)
          target.destroyed.connect(_on_target_destroyed)

  func _on_ball_hit_paddle(hit_pos: Vector3, ball: RigidBody3D) -> void:
      _combo.record_hit()
      var spin := _paddle.get_spin_from_hit(hit_pos.x)
      ball.apply_spin(spin)
      _paddle.emit_hit_sparks()
      AudioManager.play_sfx("paddle_hit")

  func _on_ball_hit_wall() -> void:
      AudioManager.play_sfx("wall_hit")

  func _on_ball_fell_out(ball: RigidBody3D) -> void:
      _balls.erase(ball)
      ball.queue_free()
      _combo.reset()
      _lives -= 1
      _hud.set_lives(_lives, _config.lives)
      if _lives <= 0:
          _end_game()
          return
      await get_tree().create_timer(0.5).timeout
      if _game_active:
          _spawn_ball()

  func _on_target_destroyed(points: int) -> void:
      _combo.record_hit()
      var earned := _combo.calculate_score(points)
      _score += earned
      _hud.set_score(_score)
      _targets_remaining -= 1
      AudioManager.play_sfx("target_hit")
      if _targets_remaining <= 0 and not _config.is_endless:
          _win_level()

  func _on_combo_changed(multiplier: int) -> void:
      _hud.set_combo(multiplier)
      if multiplier == 3:
          _hud.show_flash("COMBO x3!", 0.8)
      elif multiplier == 6:
          _hud.show_flash("COMBO x6!", 0.8)

  func _on_ultra_triggered() -> void:
      _hud.show_flash("ULTRA! x10", 1.5)
      Engine.time_scale = 0.3
      await get_tree().create_timer(1.5 * 0.3).timeout
      Engine.time_scale = 1.0

  func _win_level() -> void:
      _game_active = false
      SaveManager.set_high_score("paddleball", _config.id, _score)
      _unlock_next_level()
      _hud.show_flash("LEVEL COMPLETE!", 2.0)
      await get_tree().create_timer(2.0).timeout
      GameManager.go_to_score_screen(_score, _config.id)

  func _end_game() -> void:
      _game_active = false
      SaveManager.set_high_score("paddleball", _config.id, _score)
      _hud.show_flash("GAME OVER", 2.0)
      await get_tree().create_timer(2.0).timeout
      GameManager.go_to_score_screen(_score, _config.id)

  func _unlock_next_level() -> void:
      var order := ["rookie", "cadet", "pilot", "ace", "legend", "endless"]
      var idx := order.find(_config.id)
      if idx >= 0 and idx + 1 < order.size():
          SaveManager.unlock_level("paddleball", order[idx + 1])
  ```

- [ ] **Step 3: Run PaddleBall scene (F6)**

  Expected:
  - 3D arena visible with paddle and ball
  - Ball launches and bounces off walls
  - Paddle moves with arrow keys/mouse
  - HUD shows score, lives, level name
  - Ball hitting paddle emits sparks and advances combo

- [ ] **Step 4: Commit**

  ```bash
  git add games/paddleball/PaddleBall.tscn games/paddleball/PaddleBall.gd
  git commit -m "feat(paddleball): add PaddleBall game controller — full gameplay loop"
  ```

---

## Task 15: LevelSelect Scene

**Files:**
- Create: `games/paddleball/LevelSelect.tscn` (Godot editor)
- Create: `games/paddleball/LevelSelect.gd`

- [ ] **Step 1: Create LevelSelect scene in editor**

  New scene. Name: `LevelSelect.tscn`.
  
  Node tree:
  ```
  Control (root) — rename to LevelSelect, Full Rect
  ├── ColorRect (Background, color #070714, Full Rect)
  ├── Label (name: Title, text: "SELECT LEVEL", anchor top-center)
  ├── VBoxContainer (name: LevelList, center of screen)
  └── Button (name: BackButton, text: "← BACK", anchor bottom-left)
  ```

- [ ] **Step 2: Create LevelSelect script**

  Attach script. Save as `games/paddleball/LevelSelect.gd`:
  ```gdscript
  extends Control

  @onready var _list: VBoxContainer = $LevelList
  @onready var _back: Button = $BackButton

  func _ready() -> void:
      _back.pressed.connect(GameManager.go_to_hub)
      _build_level_buttons()

  func _build_level_buttons() -> void:
      for config in LevelConfig.get_all_levels():
          var btn := Button.new()
          var locked := not SaveManager.is_level_unlocked("paddleball", config.id)
          var best := SaveManager.get_high_score("paddleball", config.id)
          if locked:
              btn.text = "🔒 %s" % config.name
              btn.disabled = true
          else:
              btn.text = "%s   BEST: %d" % [config.name, best]
          btn.pressed.connect(_on_level_selected.bind(config.id))
          _list.add_child(btn)

      # Endless mode button (only if legend completed)
      var endless_unlocked := SaveManager.is_level_unlocked("paddleball", "endless")
      var endless_btn := Button.new()
      endless_btn.text = "🔓 ENDLESS" if endless_unlocked else "🔒 ENDLESS (complete Legend)"
      endless_btn.disabled = not endless_unlocked
      endless_btn.pressed.connect(_on_level_selected.bind("endless"))
      _list.add_child(endless_btn)

  func _on_level_selected(level_id: String) -> void:
      GameManager.start_game("paddleball", level_id)
  ```

- [ ] **Step 3: Run LevelSelect scene (F6)**

  Expected: list of 5 levels + endless. Rookie is clickable (unlocked by default). Others are locked/dimmed.

- [ ] **Step 4: Commit**

  ```bash
  git add games/paddleball/LevelSelect.tscn games/paddleball/LevelSelect.gd
  git commit -m "feat(paddleball): add LevelSelect scene with unlock gating"
  ```

---

## Task 16: Score Screen

**Files:**
- Create: `games/paddleball/ScoreScreen.tscn` (Godot editor)
- Create: `games/paddleball/ScoreScreen.gd`

- [ ] **Step 1: Create ScoreScreen scene in editor**

  New scene. Name: `ScoreScreen.tscn`.
  
  Node tree:
  ```
  Control (root) — rename to ScoreScreen, Full Rect
  ├── ColorRect (Background, color #070714, Full Rect)
  ├── Label (name: ResultTitle, text: "GAME OVER", anchor top-center)
  ├── Label (name: ScoreDisplay, anchor center)
  ├── Label (name: HighScoreDisplay, anchor center)
  ├── Button (name: RetryButton, text: "PLAY AGAIN", anchor center)
  └── Button (name: HubButton, text: "← HUB", anchor center)
  ```

- [ ] **Step 2: Create ScoreScreen script**

  Attach script. Save as `games/paddleball/ScoreScreen.gd`:
  ```gdscript
  extends Control

  @onready var _title: Label = $ResultTitle
  @onready var _score_display: Label = $ScoreDisplay
  @onready var _high_score_display: Label = $HighScoreDisplay
  @onready var _retry: Button = $RetryButton
  @onready var _hub: Button = $HubButton

  func _ready() -> void:
      var result := GameManager.get_pending_result()
      var best := SaveManager.get_high_score("paddleball", result["level"])
      _score_display.text = "SCORE: %d" % result["score"]
      _high_score_display.text = "BEST: %d" % best
      if result["score"] >= best:
          _title.text = "NEW HIGH SCORE!"
          _title.modulate = Color(1.0, 0.8, 0.0)
      _retry.pressed.connect(func(): GameManager.start_game(
          GameManager.current_game, GameManager.current_level
      ))
      _hub.pressed.connect(GameManager.go_to_hub)
  ```

- [ ] **Step 3: Commit**

  ```bash
  git add games/paddleball/ScoreScreen.tscn games/paddleball/ScoreScreen.gd
  git commit -m "feat(paddleball): add ScoreScreen with high score detection"
  ```

---

## Task 17: Screen Shake + Slow-Motion Polish

**Files:**
- Modify: `games/paddleball/Arena.gd`
- Modify: `games/paddleball/PaddleBall.gd`

- [ ] **Step 1: Add screen shake to Arena**

  Open `games/paddleball/Arena.gd` and add:
  ```gdscript
  @onready var _camera: Camera3D = $Camera

  var _shake_strength: float = 0.0
  var _shake_decay: float = 5.0

  func shake(strength: float) -> void:
      _shake_strength = strength

  func _process(delta: float) -> void:
      if _shake_strength > 0.01:
          _camera.position += Vector3(
              randf_range(-1, 1),
              randf_range(-1, 1),
              0
          ) * _shake_strength * delta
          _shake_strength = lerpf(_shake_strength, 0.0, _shake_decay * delta)
      else:
          _shake_strength = 0.0
  ```

- [ ] **Step 2: Trigger shake from PaddleBall**

  Open `games/paddleball/PaddleBall.gd`. In `_on_ball_hit_paddle()`, add:
  ```gdscript
  _arena.shake(0.05)
  ```
  
  In `_on_ball_fell_out()`, add:
  ```gdscript
  _arena.shake(0.2)
  ```
  
  In `_on_ultra_triggered()`, add before `Engine.time_scale = 0.3`:
  ```gdscript
  _arena.shake(0.3)
  ```

- [ ] **Step 3: Run PaddleBall scene and verify**

  Play to trigger a ULTRA combo (10 hits). Verify:
  - Screen shakes on paddle hits
  - Strong shake when ball falls out
  - Slow-motion activates for ~1.5s on ULTRA, then resumes

- [ ] **Step 4: Commit**

  ```bash
  git add games/paddleball/Arena.gd games/paddleball/PaddleBall.gd
  git commit -m "feat(paddleball): add screen shake and slow-motion on ULTRA combo"
  ```

---

## Task 18: Audio Integration

**Files:**
- Modify: `games/paddleball/PaddleBall.gd`
- Create: `shared/sounds/` (add placeholder .wav files here)

- [ ] **Step 1: Add placeholder audio files**

  For now, use free CC0 sound effects from https://freesound.org. Download:
  - A short thump/hit sound → save as `shared/sounds/paddle_hit.wav`
  - A wall bounce sound → save as `shared/sounds/wall_hit.wav`
  - An explosion/pop → save as `shared/sounds/target_hit.wav`
  - A chime/fanfare → save as `shared/sounds/combo_milestone.wav`
  
  Import each into Godot (drag into FileSystem panel).

- [ ] **Step 2: Register sounds in PaddleBall**

  At the top of `PaddleBall.gd`, add preloads:
  ```gdscript
  const SFX_PADDLE = preload("res://shared/sounds/paddle_hit.wav")
  const SFX_WALL = preload("res://shared/sounds/wall_hit.wav")
  const SFX_TARGET = preload("res://shared/sounds/target_hit.wav")
  const SFX_COMBO = preload("res://shared/sounds/combo_milestone.wav")
  ```
  
  In `_ready()`, after `_game_active = true`, add:
  ```gdscript
  AudioManager.register_sfx("paddle_hit", SFX_PADDLE)
  AudioManager.register_sfx("wall_hit", SFX_WALL)
  AudioManager.register_sfx("target_hit", SFX_TARGET)
  AudioManager.register_sfx("combo_milestone", SFX_COMBO)
  ```

- [ ] **Step 3: Trigger combo milestone SFX**

  In `PaddleBall.gd` → `_on_combo_changed()`, add to each branch:
  ```gdscript
  AudioManager.play_sfx("combo_milestone")
  ```

- [ ] **Step 4: Add BGM tracks per arena theme**

  Download 3 looping CC0 synth tracks from https://freesound.org. Save as:
  - `shared/sounds/bgm_neon_cyber.ogg`
  - `shared/sounds/bgm_space_station.ogg`
  - `shared/sounds/bgm_reactor_core.ogg`
  
  Import each (set **Loop** to true in the import settings).
  
  Add to `PaddleBall.gd` preloads:
  ```gdscript
  const BGM_NEON = preload("res://shared/sounds/bgm_neon_cyber.ogg")
  const BGM_SPACE = preload("res://shared/sounds/bgm_space_station.ogg")
  const BGM_REACTOR = preload("res://shared/sounds/bgm_reactor_core.ogg")
  ```
  
  In `_ready()`, after `_arena.apply_theme(...)`, add:
  ```gdscript
  var bgm_map := {
      "neon_cyber": BGM_NEON,
      "space_station": BGM_SPACE,
      "reactor_core": BGM_REACTOR,
  }
  AudioManager.register_music(_config.arena_theme, bgm_map[_config.arena_theme])
  AudioManager.play_music(_config.arena_theme)
  ```

- [ ] **Step 5: Run and verify audio**

  Play the game. Verify sounds play on paddle hit, wall bounce, and target destruction. Verify looping BGM matches the arena theme.

- [ ] **Step 5: Commit**

  ```bash
  git add shared/sounds/ games/paddleball/PaddleBall.gd
  git commit -m "feat(audio): wire SFX into paddleball gameplay events"
  ```

---

## Task 19: Full Game Flow Integration Test

**Files:**
- No new files — verify end-to-end flow

- [ ] **Step 1: Run from Main.tscn (F5)**

  Press F5 to start from the boot scene. Walk through the full flow:

  1. **Hub loads** — see Paddle Ball card, two locked cards
  2. **Click PLAY** on Paddle Ball → LevelSelect appears
  3. **Select Rookie** → PaddleBall game loads, ball launches, paddle responds
  4. **Play until game over** (miss ball 5 times) → ScoreScreen appears with score
  5. **Click PLAY AGAIN** → game restarts
  6. **Click HUB** → back to hub

- [ ] **Step 2: Verify level unlock flow**

  Manually call in Godot editor's script console to simulate completing Rookie:
  ```gdscript
  SaveManager.unlock_level("paddleball", "cadet")
  ```
  Then navigate to LevelSelect. Verify Cadet is now unlocked.

- [ ] **Step 3: Verify high score persistence**

  Quit the game, reopen. Navigate to LevelSelect. Verify previous best score still shows.

- [ ] **Step 4: Commit**

  ```bash
  git add .
  git commit -m "test: verify full hub→level select→game→score screen flow"
  ```

---

## Task 20: macOS Desktop Export

**Files:**
- Create: `export_presets.cfg` (generated by Godot editor)

- [ ] **Step 1: Download export templates**

  In Godot editor: **Editor → Manage Export Templates** → **Download and Install** for Godot 4.3 stable.

- [ ] **Step 2: Configure macOS export preset**

  **Project → Export** → click **Add** → select **macOS**.
  
  Set:
  - Application → Name: `Kids Arcade`
  - Application → Identifier: `com.kidsarcade.app`
  - Application → Version: `1.0.0`
  - Check **Embed PCK**

- [ ] **Step 3: Export**

  Click **Export Project**. Save to `builds/KidsArcade.app`.
  
  Open the exported `.app` directly from Finder. Verify:
  - App launches without Godot editor
  - Hub appears correctly
  - Paddleball game runs at full resolution

- [ ] **Step 4: Commit export preset**

  ```bash
  git add export_presets.cfg
  git commit -m "chore: add macOS export preset"
  ```

---

## Running All Tests

```bash
# Run all GUT tests headlessly
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit

# Expected output:
# Tests passed: 22
# Tests failed: 0
```

---

## Success Criteria Checklist

- [ ] Hub launcher opens with Neon Arcade aesthetic, shows Paddleball card
- [ ] LevelSelect shows 5 levels with correct lock/unlock state
- [ ] All 5 difficulty levels are playable end-to-end
- [ ] Endless mode unlocks after completing Legend
- [ ] Combo system: x3 at 3 hits, x6 at 6, x10 ULTRA at 10
- [ ] ULTRA triggers 1.5s slow-motion and screen flash
- [ ] GPU particles active on ball trail, impacts, target destruction
- [ ] Bloom and glow post-processing visible
- [ ] Screen shake triggers on paddle hits and ball loss
- [ ] Scores persist across sessions via SaveManager
- [ ] All GUT tests pass (22 tests)
- [ ] macOS export runs as standalone .app
