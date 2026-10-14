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
