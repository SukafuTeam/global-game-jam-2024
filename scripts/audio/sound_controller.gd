extends Node

# SFX Fields
@export_subgroup("SFX")
@export var sfx_bus: String = "Master"
@export var num_players:int = 12
var available: Array[AudioStreamPlayer] = []
var queue: Array[SoundEffect] = []

# BMG Fields
@export_subgroup("BMG")
@export var bmg_bus: String = "Master"
@onready var bmg_player: AudioStreamPlayer = $BMG
var current_bmg_name: String = ""

func _ready():
	bmg_player.volume_db = linear_to_db(0.8)
	# For each possible effect we can play
	for i in num_players:
		# Create a new player
		var player = AudioStreamPlayer.new()
		# Adds it to the scene
		add_child(player)
		# Adds it to the available array
		available.append(player)
		# Connects its finished signal to reenter the available array
		player.finished.connect(on_stream_finised.bind(player))
		# Set its audio bus
		player.bus = sfx_bus

#region: SFX Processing
func on_stream_finised(stream):
	available.append(stream)

func play_sfx(effect: AudioStream, volume: float = -1.0, pitch: float = -1.0):
	if effect == null:
		push_warning("Trying to play a null sfx")
		return
	
	# Adds a new effect to be played
	queue.append(SoundEffect.new(effect, volume, pitch))

func _process(_delta):
	# If there's no sounds to be played, or no available players, return early
	if queue.is_empty() or available.is_empty():
		return

	# Gets the player, and the effect to be played
	var player = available.pop_front() as AudioStreamPlayer
	var effect = queue.pop_front() as SoundEffect
	
	# Sets up stream and volume
	player.stream = effect.stream
	var f_volume = effect.volume if effect.volume != -1 else 1
	player.volume_db = linear_to_db(f_volume)
	
	var f_pitch  = effect.pitch if effect.pitch != -1 else 1
	player.pitch_scale = f_pitch
	
	# And finally play the effect
	player.play()
#endregion

#region: BMG Processing
func change_bmg(new_name: String, stream: AudioStream):
	# If we're already playing this bmg, return
	if current_bmg_name == new_name:
		return
		
	# Or if the stream is null, with a warn
	if stream == null:
		push_warning("Trying to change BMG to a null stream")
		return
	
	current_bmg_name = new_name
	bmg_player.stop()
	bmg_player.stream = stream
	bmg_player.play()

func pause_bmg():
	bmg_player.stream_paused = true

func resume_bmg():
	bmg_player.stream_paused = false

func stop_bmg():
	bmg_player.stop()

func play_bmg():
	if bmg_player.stream == null:
		return
	
	bmg_player.play()
#endregion
