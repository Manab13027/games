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
