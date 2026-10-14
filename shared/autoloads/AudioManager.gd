extends Node

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _music_tracks: Dictionary = {}
var _sfx_sounds: Dictionary = {}

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)

	await get_tree().process_frame
	_apply_volume_settings()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")

func register_music(track_name: String, stream: AudioStream) -> void:
	_music_tracks[track_name] = stream

func register_sfx(sound_name: String, stream: AudioStream) -> void:
	_sfx_sounds[sound_name] = stream

func play_music(track_name: String) -> void:
	if not _music_tracks.has(track_name):
		return
	if _music_player.stream == _music_tracks[track_name] and _music_player.playing:
		return
	_music_player.stream = _music_tracks[track_name]
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func play_sfx(sound_name: String) -> void:
	if not _sfx_sounds.has(sound_name):
		return
	var player = AudioStreamPlayer.new()
	player.stream = _sfx_sounds[sound_name]
	player.bus = "SFX"
	player.autoplay = true
	add_child(player)
	player.finished.connect(player.queue_free)

func _apply_volume_settings() -> void:
	var master_vol: float = SaveManager.get_setting("master_volume", 1.0)
	var music_vol: float = SaveManager.get_setting("music_volume", 0.8)
	var sfx_vol: float = SaveManager.get_setting("sfx_volume", 1.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"), linear_to_db(master_vol)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"), linear_to_db(music_vol)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"), linear_to_db(sfx_vol)
	)
