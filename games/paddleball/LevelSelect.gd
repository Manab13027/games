extends Control

const LevelConfig = preload("res://games/paddleball/LevelConfig.gd")

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
        _style_button(btn)
        _list.add_child(btn)

    # Endless mode button
    var endless_unlocked := SaveManager.is_level_unlocked("paddleball", "endless")
    var endless_btn := Button.new()
    endless_btn.text = "🔓 ENDLESS" if endless_unlocked else "🔒 ENDLESS (complete Legend)"
    endless_btn.disabled = not endless_unlocked
    endless_btn.pressed.connect(_on_level_selected.bind("endless"))
    _style_button(endless_btn)
    _list.add_child(endless_btn)

func _style_button(btn: Button) -> void:
    btn.custom_minimum_size = Vector2(0, 56)
    btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn.add_theme_color_override("font_color", Color.WHITE)
    btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.7, 1.0))
    btn.add_theme_font_size_override("font_size", 22)

func _on_level_selected(level_id: String) -> void:
    GameManager.start_game("paddleball", level_id)
