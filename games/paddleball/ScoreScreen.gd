extends Control

@onready var _title: Label = $ResultTitle
@onready var _score_display: Label = $ScoreDisplay
@onready var _high_score_display: Label = $HighScoreDisplay
@onready var _retry: Button = $RetryButton
@onready var _hub: Button = $HubButton

func _ready() -> void:
    var result := GameManager.get_pending_result()
    var level_id: String = result.get("level", "rookie")
    var score: int = result.get("score", 0)
    var best := SaveManager.get_high_score("paddleball", level_id)

    _score_display.text = "SCORE: %d" % score
    _high_score_display.text = "BEST: %d" % best

    if score >= best and score > 0:
        _title.text = "NEW HIGH SCORE!"
        _title.modulate = Color(1.0, 0.8, 0.0)
    else:
        _title.text = "GAME OVER"
        _title.modulate = Color.WHITE

    var game := GameManager.current_game
    var level := GameManager.current_level
    _retry.pressed.connect(func(): GameManager.start_game(game, level))
    _hub.pressed.connect(GameManager.go_to_hub)
