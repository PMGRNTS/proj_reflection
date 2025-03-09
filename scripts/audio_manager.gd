extends Node

# Sound categories for volume control
enum SoundType {SFX, UI}

# Volume levels (0-1)
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var ui_volume: float = 1.0

# Sound resources
var sounds = {
	# Player movement sounds
	"dash": preload("res://assets/sounds/dash.wav"),
	"fire": preload("res://assets/sounds/fire.wav"),
	"reflect_up": preload("res://assets/sounds/reflect_up.wav"),
	"reflect_catch": preload("res://assets/sounds/reflect_catch.wav"),
	"hit_normal": preload("res://assets/sounds/hit_normal.wav"),
	"hit_reflected": preload("res://assets/sounds/hit_reflected.wav"),
	"hit_impact": preload("res://assets/sounds/hit_impact.wav"), # Add a chunky impact sound
	"hit_boom": preload("res://assets/sounds/hit_boom.wav"),  
	# UI sounds - you can add these later
	"button_click": null,
	"menu_open": null,
}

# Sound players pool
var available_players: Array[AudioStreamPlayer] = []
var max_players: int = 16  # Adjust based on your needs

func _ready():
	print("AudioManager initializing...")
	# Create the pool of audio players
	for i in range(max_players):
		var player = AudioStreamPlayer.new()
		add_child(player)
		available_players.append(player)
		# Connect signal to know when the player is available again
		player.finished.connect(_on_sound_finished.bind(player))
	print("AudioManager: Created pool of", max_players, "audio players")

func play_sound(sound_name: String, type: SoundType = SoundType.SFX) -> AudioStreamPlayer:
	if not sounds.has(sound_name) or sounds[sound_name] == null:
		print("AudioManager: Sound not found:", sound_name)
		return null
	
	# Find an available player
	if available_players.size() <= 0:
		print("AudioManager: No available audio players!")
		return null
	
	var player = available_players.pop_back()
	player.stream = sounds[sound_name]
	
	# Set volume based on sound type
	var volume_db = linear_to_db(master_volume * (sfx_volume if type == SoundType.SFX else ui_volume))
	player.volume_db = volume_db
	
	player.play()
	return player

func play_sound_with_pitch(sound_name: String, pitch: float = 1.0, type: SoundType = SoundType.SFX) -> AudioStreamPlayer:
	var player = play_sound(sound_name, type)
	if player:
		player.pitch_scale = pitch
	return player

func _on_sound_finished(player: AudioStreamPlayer) -> void:
	# Reset to default values
	player.pitch_scale = 1.0
	player.volume_db = 0.0
	
	# Make player available again
	if not available_players.has(player):
		available_players.append(player)

# Spatial sound for positional audio (useful for player actions)
func play_sound_at_position(sound_name: String, position: Vector2) -> void:
	# Create a temporary audio player at the specified position
	var player = AudioStreamPlayer2D.new()
	add_child(player)
	player.position = position
	
	if sounds.has(sound_name) and sounds[sound_name] != null:
		player.stream = sounds[sound_name]
		player.volume_db = linear_to_db(master_volume * sfx_volume)
		player.play()
		
		# Remove player when sound finished
		await player.finished
		player.queue_free()
		
# Add a new function for layered hit sounds
func play_hit_impact(position: Vector2, is_reflected: bool = false):
	# Play the base hit sound
	play_sound("hit_reflected" if is_reflected else "hit_normal")
	
	# Layer a chunky impact sound with slight pitch variation
	var impact = play_sound("hit_impact")
	if impact:
		impact.volume_db += 2.0  # Make it slightly louder
	# #
