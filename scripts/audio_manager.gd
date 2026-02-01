extends Node

@onready var music_player := AudioStreamPlayer.new()
var _music_loop: bool = false

func _ready() -> void:
	music_player.bus = "Music"
	music_player.volume_db = -6.0
	add_child(music_player)
	# reconnect finished in case we need manual looping
	if not music_player.is_connected("finished", Callable(self, "_on_music_finished")):
		music_player.finished.connect(_on_music_finished)


func play_music(stream: AudioStream, volume_db: float = 0.0, loop: bool = true) -> void:
	"""
	Play a music stream. Use `loop` to request that the track restarts when finished.
	"""
	_music_loop = loop
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()

func stop_music() -> void:
	_music_loop = false
	music_player.stop()

func _on_music_finished() -> void:
	if _music_loop:
		# restart the same stream
		music_player.play()
