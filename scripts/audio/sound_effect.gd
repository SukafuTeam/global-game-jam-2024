extends Node
class_name SoundEffect

var stream: AudioStream
var volume: float

func _init(_stream: AudioStream, _volume: float = -1):
	stream = _stream
	volume = _volume
