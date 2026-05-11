extends RefCounted

static func get_all_levels() -> Array:
	return [rookie(), cadet(), pilot(), ace(), legend()]

static func rookie() -> Dictionary:
	return {
		"name": "Rookie", "id": "rookie",
		"ball_speed": 8.0, "paddle_width": 2.0,
		"target_count": 0, "targets_move": false,
		"multi_ball": false, "moving_walls": false,
		"obstacles": false, "arena_theme": "neon_cyber",
		"lives": 5, "is_endless": false
	}

static func cadet() -> Dictionary:
	return {
		"name": "Cadet", "id": "cadet",
		"ball_speed": 12.0, "paddle_width": 1.5,
		"target_count": 6, "targets_move": false,
		"multi_ball": false, "moving_walls": false,
		"obstacles": false, "arena_theme": "neon_cyber",
		"lives": 4, "is_endless": false
	}

static func pilot() -> Dictionary:
	return {
		"name": "Pilot", "id": "pilot",
		"ball_speed": 16.0, "paddle_width": 1.5,
		"target_count": 8, "targets_move": true,
		"multi_ball": false, "moving_walls": false,
		"obstacles": false, "arena_theme": "space_station",
		"lives": 3, "is_endless": false
	}

static func ace() -> Dictionary:
	return {
		"name": "Ace", "id": "ace",
		"ball_speed": 20.0, "paddle_width": 1.0,
		"target_count": 10, "targets_move": true,
		"multi_ball": true, "moving_walls": false,
		"obstacles": true, "arena_theme": "space_station",
		"lives": 3, "is_endless": false
	}

static func legend() -> Dictionary:
	return {
		"name": "Legend", "id": "legend",
		"ball_speed": 25.0, "paddle_width": 1.0,
		"target_count": 12, "targets_move": true,
		"multi_ball": true, "moving_walls": true,
		"obstacles": true, "arena_theme": "reactor_core",
		"lives": 2, "is_endless": false
	}

static func endless() -> Dictionary:
	return {
		"name": "Endless", "id": "endless",
		"ball_speed": 30.0, "paddle_width": 1.0,
		"target_count": 0, "targets_move": true,
		"multi_ball": true, "moving_walls": true,
		"obstacles": true, "arena_theme": "reactor_core",
		"lives": 3, "is_endless": true
	}
