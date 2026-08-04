class_name SettingsStore
extends RefCounted

const SCHEMA_VERSION: int = 1
const DEFAULT_PLAYBACK_SPEED: int = 1

var _path: String


func _init(path: String = "user://settings.json") -> void:
	_path = path


func load_playback_speed() -> int:
	if not FileAccess.file_exists(_path):
		return DEFAULT_PLAYBACK_SPEED
	var file := FileAccess.open(_path, FileAccess.READ)
	if file == null:
		return DEFAULT_PLAYBACK_SPEED
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return DEFAULT_PLAYBACK_SPEED
	var parsed = json.data
	if not (parsed is Dictionary):
		return DEFAULT_PLAYBACK_SPEED
	var values: Dictionary = parsed
	if int(values.get("schema_version", -1)) != SCHEMA_VERSION:
		return DEFAULT_PLAYBACK_SPEED
	var speed: int = int(values.get("playback_speed", DEFAULT_PLAYBACK_SPEED))
	return speed if speed in [1, 2, 4] else DEFAULT_PLAYBACK_SPEED


func save_playback_speed(speed: int) -> bool:
	if not speed in [1, 2, 4]:
		return false
	var file := FileAccess.open(_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({
		"schema_version": SCHEMA_VERSION,
		"playback_speed": speed,
	}) + "\n")
	return true
