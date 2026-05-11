extends Node3D

const TARGET_SCENE = preload("res://games/paddleball/Target.tscn")
const BALL_SCENE = preload("res://games/paddleball/Ball.tscn")
const ComboSystem = preload("res://games/paddleball/ComboSystem.gd")
const LevelConfig = preload("res://games/paddleball/LevelConfig.gd")
const SPEED_TICK: float = 5.0

@onready var _arena: Node3D = $Arena
@onready var _paddle: StaticBody3D = $Paddle
@onready var _hud: CanvasLayer = $HUD
@onready var _targets_root: Node3D = $TargetsRoot

var _config: Dictionary
var _combo: RefCounted
var _score: int = 0
var _lives: int = 3
var _balls: Array = []
var _targets_remaining: int = 0
var _game_active: bool = false
var _elapsed: float = 0.0
var _next_speed_tick: float = SPEED_TICK

# Audio streams loaded at runtime to avoid import errors on placeholder files
var _sfx: Dictionary = {}
var _bgm: Dictionary = {}

func _ready() -> void:
	_config = _get_level_config()
	_combo = ComboSystem.new()
	_combo.combo_changed.connect(_on_combo_changed)
	_combo.ultra_triggered.connect(_on_ultra_triggered)

	_lives = _config["lives"]
	_paddle.set_width(_config["paddle_width"])
	_arena.apply_theme(_arena.get_theme_from_string(_config["arena_theme"]))

	_hud.set_score(0)
	_hud.set_level(_config["name"])
	_hud.set_lives(_lives, _config["lives"])
	_hud.set_combo(1)

	_load_audio()
	_spawn_targets()
	_spawn_ball()
	_game_active = true

func _load_audio() -> void:
	var sfx_paths := {
		"paddle_hit": "res://shared/sounds/paddle_hit.wav",
		"wall_hit": "res://shared/sounds/wall_hit.wav",
		"target_hit": "res://shared/sounds/target_hit.wav",
		"combo_milestone": "res://shared/sounds/combo_milestone.wav",
	}
	for key in sfx_paths:
		var stream = load(sfx_paths[key])
		if stream:
			_sfx[key] = stream
			AudioManager.register_sfx(key, stream)

	var bgm_paths := {
		"neon_cyber": "res://shared/sounds/bgm_neon_cyber.wav",
		"space_station": "res://shared/sounds/bgm_space_station.wav",
		"reactor_core": "res://shared/sounds/bgm_reactor_core.wav",
	}
	var theme: String = _config["arena_theme"]
	if bgm_paths.has(theme):
		var stream = load(bgm_paths[theme])
		if stream:
			AudioManager.register_music(theme, stream)
			AudioManager.play_music(theme)

func _physics_process(delta: float) -> void:
	if not _game_active:
		return
	_elapsed += delta
	if _elapsed >= _next_speed_tick:
		_next_speed_tick += SPEED_TICK
		for ball in _balls:
			if is_instance_valid(ball):
				ball.accelerate()
		if _balls.size() > 0 and is_instance_valid(_balls[0]):
			_arena.update_camera_fov(_balls[0].get_speed(), 40.0)

func _get_level_config() -> Dictionary:
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
	ball.launch(_config["ball_speed"])
	_balls.append(ball)

func _spawn_targets() -> void:
	_targets_remaining = _config["target_count"]
	if _config["target_count"] == 0:
		return
	var point_values := [100, 300, 500]
	for i: int in _config["target_count"]:
		var target: Area3D = TARGET_SCENE.instantiate()
		_targets_root.add_child(target)
		var col: int = i % 3
		var row: int = i / 3
		target.position = Vector3(-4.0 + col * 4.0, 2.0 + row * 1.5, -5.0 - row * 1.0)
		target.setup(point_values[col], _config["targets_move"])
		target.destroyed.connect(_on_target_destroyed)

func _on_ball_hit_paddle(hit_pos: Vector3, ball: RigidBody3D) -> void:
	_combo.record_hit()
	var spin: float = _paddle.get_spin_from_hit(hit_pos.x)
	ball.apply_spin(spin)
	_paddle.emit_hit_sparks()
	_arena.shake(0.05)
	AudioManager.play_sfx("paddle_hit")

func _on_ball_hit_wall() -> void:
	AudioManager.play_sfx("wall_hit")

func _on_ball_fell_out(ball: RigidBody3D) -> void:
	if not _game_active:
		return
	_balls.erase(ball)
	if is_instance_valid(ball):
		ball.queue_free()
	_combo.reset()
	_lives -= 1
	_hud.set_lives(_lives, _config["lives"])
	_arena.shake(0.2)
	if _lives <= 0:
		_end_game()
		return
	await get_tree().create_timer(0.5).timeout
	if _game_active:
		_spawn_ball()

func _on_target_destroyed(points: int) -> void:
	_combo.record_hit()
	var earned: int = _combo.calculate_score(points)
	_score += earned
	_hud.set_score(_score)
	_targets_remaining -= 1
	AudioManager.play_sfx("target_hit")
	if _targets_remaining <= 0 and not _config["is_endless"]:
		_win_level()

func _on_combo_changed(multiplier: int) -> void:
	_hud.set_combo(multiplier)
	if multiplier == 6:
		_hud.show_flash("COMBO x6!", 0.8)
		AudioManager.play_sfx("combo_milestone")
	elif multiplier == 3:
		_hud.show_flash("COMBO x3!", 0.8)
		AudioManager.play_sfx("combo_milestone")

func _on_ultra_triggered() -> void:
	AudioManager.play_sfx("combo_milestone")
	_hud.show_flash("ULTRA! x10", 1.5)
	_arena.shake(0.3)
	Engine.time_scale = 0.3
	await get_tree().create_timer(1.5 * 0.3).timeout
	Engine.time_scale = 1.0

func _win_level() -> void:
	Engine.time_scale = 1.0
	_game_active = false
	SaveManager.set_high_score("paddleball", _config["id"], _score)
	_unlock_next_level()
	_hud.show_flash("LEVEL COMPLETE!", 2.0)
	await get_tree().create_timer(2.0).timeout
	GameManager.go_to_score_screen(_score, _config["id"])

func _end_game() -> void:
	Engine.time_scale = 1.0
	_game_active = false
	SaveManager.set_high_score("paddleball", _config["id"], _score)
	_hud.show_flash("GAME OVER", 2.0)
	await get_tree().create_timer(2.0).timeout
	GameManager.go_to_score_screen(_score, _config["id"])

func _unlock_next_level() -> void:
	var order := ["rookie", "cadet", "pilot", "ace", "legend", "endless"]
	var idx: int = order.find(_config["id"])
	if idx >= 0 and idx + 1 < order.size():
		SaveManager.unlock_level("paddleball", order[idx + 1])
