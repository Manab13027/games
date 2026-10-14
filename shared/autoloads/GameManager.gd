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
