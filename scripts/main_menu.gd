extends Control

@onready var play_button = $CenterContainer/VBoxContainer/Play
@onready var options_button = $CenterContainer/VBoxContainer/Options

@onready var input_selection_menu = $"../InputSelectionMenu"  # Note the path change
@onready var main_container = $CenterContainer


signal inputs_selected(p1_keyboard: bool, p2_keyboard: bool)

func _ready():
	# Hide input selection menu at start
	if input_selection_menu:
		input_selection_menu.hide()
		# Listen for when input selection is complete
		input_selection_menu.inputs_selected.connect(_on_inputs_selected)
	else:
		push_error("InputSelectionMenu not found!")


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
