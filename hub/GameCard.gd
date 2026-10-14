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
