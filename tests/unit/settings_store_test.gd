extends "res://tests/framework/test_case.gd"

const SettingsStoreScript = preload("res://src/application/settings_store.gd")


func test_settings_round_trip_and_invalid_data_fall_back_safely() -> void:
	var path := "user://settings_store_test.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var store = SettingsStoreScript.new(path)
	assert_equal(store.load_playback_speed(), 1)
	assert_true(store.save_playback_speed(4))
	assert_equal(SettingsStoreScript.new(path).load_playback_speed(), 4)
	assert_false(store.save_playback_speed(3))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{ invalid")
	file.close()
	assert_equal(SettingsStoreScript.new(path).load_playback_speed(), 1)
	DirAccess.remove_absolute(path)
