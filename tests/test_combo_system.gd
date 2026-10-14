extends GutTest

var combo: ComboSystem

func before_each() -> void:
	combo = ComboSystem.new()

func test_initial_multiplier_is_one() -> void:
	assert_eq(combo.multiplier, 1)

func test_three_hits_gives_x3() -> void:
	combo.record_hit()
	combo.record_hit()
	combo.record_hit()
	assert_eq(combo.multiplier, 3)

func test_six_hits_gives_x6() -> void:
	for i in 6:
		combo.record_hit()
	assert_eq(combo.multiplier, 6)

func test_ten_hits_gives_x10() -> void:
	for i in 10:
		combo.record_hit()
	assert_eq(combo.multiplier, 10)

func test_reset_sets_multiplier_to_one() -> void:
	for i in 6:
		combo.record_hit()
	combo.reset()
	assert_eq(combo.multiplier, 1)

func test_calculate_score_applies_multiplier() -> void:
	for i in 3:
		combo.record_hit()
	assert_eq(combo.calculate_score(100), 300)

func test_ultra_signal_fires_at_ten_hits() -> void:
	watch_signals(combo)
	for i in 10:
		combo.record_hit()
	assert_signal_emitted(combo, "ultra_triggered")

func test_ultra_signal_not_fired_at_nine_hits() -> void:
	watch_signals(combo)
	for i in 9:
		combo.record_hit()
	assert_signal_not_emitted(combo, "ultra_triggered")
