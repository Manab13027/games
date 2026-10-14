extends GutTest

var sm: SaveManager

func before_each() -> void:
    sm = SaveManager.new()
    # Use a temp save path for tests
    sm._save_path = "user://test_save.json"
    sm._data = sm._default_data()

func test_default_high_score_is_zero() -> void:
    assert_eq(sm.get_high_score("paddleball", "rookie"), 0)

func test_set_high_score_persists_higher_value() -> void:
    sm.set_high_score("paddleball", "rookie", 500)
    assert_eq(sm.get_high_score("paddleball", "rookie"), 500)

func test_set_high_score_ignores_lower_value() -> void:
    sm.set_high_score("paddleball", "rookie", 500)
    sm.set_high_score("paddleball", "rookie", 100)
    assert_eq(sm.get_high_score("paddleball", "rookie"), 500)

func test_rookie_unlocked_by_default() -> void:
    assert_true(sm.is_level_unlocked("paddleball", "rookie"))

func test_cadet_locked_by_default() -> void:
    assert_false(sm.is_level_unlocked("paddleball", "cadet"))

func test_unlock_level_works() -> void:
    sm.unlock_level("paddleball", "cadet")
    assert_true(sm.is_level_unlocked("paddleball", "cadet"))

func test_get_setting_returns_default() -> void:
    assert_eq(sm.get_setting("master_volume", 1.0), 1.0)

func test_set_setting_persists_value() -> void:
    sm.set_setting("master_volume", 0.5)
    assert_eq(sm.get_setting("master_volume", 1.0), 0.5)
