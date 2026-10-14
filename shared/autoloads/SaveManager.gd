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
