extends Control

@onready var play_button = $CenterContainer/VBoxContainer/Play

@onready var exit_button = $CenterContainer/VBoxContainer/Exit
@onready var settings_button = $CenterContainer/VBoxContainer/Settings

@onready var input_selection_menu = $"../InputSelectionMenu"
@onready var settings_menu = $"../SettingsMenu"
@onready var main_container = $CenterContainer

signal inputs_selected(p1_keyboard: bool, p2_keyboard: bool)

func _ready():
	print("Main menu initializing...")
	
	# Connect button signals - this is safer than connecting in the editor
	# as it allows for more error checking
	if play_button:
		if !play_button.is_connected("pressed", _on_play_pressed):
			play_button.pressed.connect(_on_play_pressed)
	else:
		push_error("Play button not found!")
		
	if exit_button:
		if !exit_button.is_connected("pressed", _on_exit_pressed):
			exit_button.pressed.connect(_on_exit_pressed)
	else:
		push_error("Exit button not found!")
	
	# Settings button might not exist yet if you're in the process of adding it
	if settings_button:
		print("Found settings button, connecting signal")
		#settings_button.pressed.connect(_on_settings_pressed)
	else:
		push_warning("Settings button not found - if you're adding a new Settings button, ignore this warning")
		
	# Hide input selection menu at start
	if input_selection_menu:
		input_selection_menu.hide()
		# Listen for when input selection is complete
		if !input_selection_menu.is_connected("inputs_selected", _on_inputs_selected):
			input_selection_menu.inputs_selected.connect(_on_inputs_selected)
	else:
		push_error("InputSelectionMenu not found!")
	
	# Initialize settings menu if it exists
	if settings_menu:
		settings_menu.hide()
	else:
		push_warning("SettingsMenu not found - if you're adding a new Settings menu, ignore this warning")
	
	print("Main menu initialization complete")

func _on_settings_pressed() -> void:
	print("Settings button pressed")
	if settings_menu:
		settings_menu.open_settings()
	else:
		push_error("Cannot open settings menu - menu not found!")


		
func _on_play_pressed() -> void:
	# When Play is pressed, show the input selection menu
	if input_selection_menu:
		hide()  # Hide main menu
		input_selection_menu.show()

func _on_options_pressed() -> void:
	# We can implement options menu later
	print("Options menu not implemented yet")

func _on_inputs_selected(p1_keyboard: bool, p2_keyboard: bool) -> void:
	print("Inputs selected - P1 Keyboard:", p1_keyboard, " P2 Keyboard:", p2_keyboard)
	# Store input preferences in GameManager
	GameManager.p1_using_keyboard = p1_keyboard
	GameManager.p2_using_keyboard = p2_keyboard
	# Start the game
	GameManager.start_game()



func _on_exit_pressed() -> void:
	get_tree().quit()
