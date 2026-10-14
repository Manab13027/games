extends CanvasLayer

@onready var _score: Label = $ScoreLabel
@onready var _level: Label = $LevelLabel
@onready var _lives_container: HBoxContainer = $LivesContainer
@onready var _combo: Label = $ComboLabel
@onready var _flash: Label = $FlashText


func set_score(value: int) -> void:
    _score.text = "SCORE: %d" % value

func set_level(level_name: String) -> void:
    _level.text = level_name

func set_lives(current: int, max_lives: int) -> void:
    for child in _lives_container.get_children():
        child.free()
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
        if multiplier >= 10:
            _combo.modulate = Color(1.0, 0.2, 0.0)   # red at x10 ULTRA
        elif multiplier >= 6:
            _combo.modulate = Color(1.0, 0.5, 0.0)   # orange at x6+
        elif multiplier >= 3:
            _combo.modulate = Color(1.0, 0.85, 0.0)  # gold at x3+
        else:
            _combo.modulate = Color.WHITE             # x2 — no highlight

func show_flash(text: String, duration: float = 1.5) -> void:
    _flash.text = text
    _flash.visible = true
    await get_tree().create_timer(duration).timeout
    if is_instance_valid(self):
        _flash.visible = false
