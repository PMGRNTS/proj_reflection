extends Node

# Settings data
var audio_settings = {
	"master_volume": 5,  # 1-5 scale
	"sfx_volume": 5,     # 1-5 scale
	"ui_volume": 5       # 1-5 scale
}

var gameplay_settings = {
	"dash_cooldown": 0.8,
	"fire_cooldown": 0.75,
	"reflect_duration": 0.7
}

var video_settings = {
	"fullscreen": false
}

# Save file path
const SAVE_PATH = "user://settings.cfg"

func _ready():
	print("Settings Manager initializing...")
	load_settings()
	
	# Apply settings on startup
	apply_audio_settings()
	apply_video_settings()

# Save settings to disk
func save_settings():
	var config = ConfigFile.new()
	
	# Audio section
	config.set_value("audio", "master_volume", audio_settings.master_volume)
	config.set_value("audio", "sfx_volume", audio_settings.sfx_volume)
	config.set_value("audio", "ui_volume", audio_settings.ui_volume)
	
	# Gameplay section
	config.set_value("gameplay", "dash_cooldown", gameplay_settings.dash_cooldown)
	config.set_value("gameplay", "fire_cooldown", gameplay_settings.fire_cooldown)
	config.set_value("gameplay", "reflect_duration", gameplay_settings.reflect_duration)
	
	# Video section
	config.set_value("video", "fullscreen", video_settings.fullscreen)
	
	# Save to file
	var error = config.save(SAVE_PATH)
	if error != OK:
		print("Failed to save settings: ", error)
		return false
	
	print("Settings saved successfully")
	return true

# Load settings from disk
func load_settings():
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	
	# If the file doesn't exist or has errors, use defaults
	if error != OK:
		print("No settings file found or error loading, using defaults")
		return
	
	# Audio settings
	if config.has_section("audio"):
		audio_settings.master_volume = config.get_value("audio", "master_volume", audio_settings.master_volume)
		audio_settings.sfx_volume = config.get_value("audio", "sfx_volume", audio_settings.sfx_volume)
		audio_settings.ui_volume = config.get_value("audio", "ui_volume", audio_settings.ui_volume)
	
	# Gameplay settings
	if config.has_section("gameplay"):
		gameplay_settings.dash_cooldown = config.get_value("gameplay", "dash_cooldown", gameplay_settings.dash_cooldown)
		gameplay_settings.fire_cooldown = config.get_value("gameplay", "fire_cooldown", gameplay_settings.fire_cooldown)
		gameplay_settings.reflect_duration = config.get_value("gameplay", "reflect_duration", gameplay_settings.reflect_duration)
	
	# Video settings
	if config.has_section("video"):
		video_settings.fullscreen = config.get_value("video", "fullscreen", video_settings.fullscreen)
	
	print("Settings loaded successfully")

# Apply audio settings to the game
func apply_audio_settings():
	# Scale values from 1-5 to 0-1 range
	var master_scaled = audio_settings.master_volume / 5.0
	var sfx_scaled = audio_settings.sfx_volume / 5.0
	var ui_scaled = audio_settings.ui_volume / 5.0
	
	# Apply to AudioManager
	if has_node("/root/AudioManager"):
		AudioManager.master_volume = master_scaled
		AudioManager.sfx_volume = sfx_scaled
		AudioManager.ui_volume = ui_scaled
		print("Applied audio settings - Master:", master_scaled, " SFX:", sfx_scaled, " UI:", ui_scaled)

# Apply gameplay settings to the game
func apply_gameplay_settings():
	print("Applied gameplay settings")
	# These will be applied when a new game starts via GameManager

# Apply video settings to the game
func apply_video_settings():
	if video_settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	print("Applied video setting - Fullscreen:", video_settings.fullscreen)

# Set volume settings (1-5 scale)
func set_master_volume(value: int):
	audio_settings.master_volume = clamp(value, 1, 5)
	apply_audio_settings()

func set_sfx_volume(value: int):
	audio_settings.sfx_volume = clamp(value, 1, 5)
	apply_audio_settings()

func set_ui_volume(value: int):
	audio_settings.ui_volume = clamp(value, 1, 5)
	apply_audio_settings()

# Set gameplay settings
func set_dash_cooldown(value: float):
	gameplay_settings.dash_cooldown = value
	# This will be applied when the game starts

func set_fire_cooldown(value: float):
	gameplay_settings.fire_cooldown = value
	# This will be applied when the game starts

func set_reflect_duration(value: float):
	gameplay_settings.reflect_duration = value
	# This will be applied when the game starts

# Set video settings
func set_fullscreen(value: bool):
	video_settings.fullscreen = value
	apply_video_settings()
