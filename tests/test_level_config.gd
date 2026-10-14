extends GutTest

func test_get_all_levels_returns_five() -> void:
	assert_eq(LevelConfig.get_all_levels().size(), 5)

func test_rookie_has_no_targets() -> void:
	assert_eq(LevelConfig.rookie().target_count, 0)

func test_legend_has_moving_walls() -> void:
	assert_true(LevelConfig.legend().moving_walls)

func test_cadet_has_static_targets() -> void:
	var c = LevelConfig.cadet()
	assert_gt(c.target_count, 0)
	assert_false(c.targets_move)

func test_pilot_targets_move() -> void:
	assert_true(LevelConfig.pilot().targets_move)

func test_ace_has_multi_ball() -> void:
	assert_true(LevelConfig.ace().multi_ball)

func test_endless_config_base_speed_is_max() -> void:
	var e = LevelConfig.endless()
	assert_gt(e.ball_speed, LevelConfig.legend().ball_speed)
