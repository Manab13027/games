extends Node

func _ready() -> void:
    await get_tree().create_timer(0.1).timeout
    GameManager.go_to_hub()
