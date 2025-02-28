extends Control

signal inputs_selected(p1_keyboard: bool, p2_keyboard: bool)

# These variables belong to the input selection menu scene
@onready var p1_toggle = %InputToggle  # Using unique names to find nodes
@onready var p2_toggle = %InputToggle2  # Make sure to give unique names in the editor
@onready var confirm_button = %Confirm  # Give the button a unique name in the editor

func _ready():
	print("Input Selection Menu loading...")
	
	# Verify our nodes are found
	var nodes_found = true
	if !p1_toggle:
		push_error("Player 1 toggle not found!")
		nodes_found = false
	if !p2_toggle:
		push_error("Player 2 toggle not found!")
		nodes_found = false
	if !confirm_button:
		push_error("Confirm button not found!")
		nodes_found = false
		
	if !nodes_found:
		return
		
	print("All nodes found successfully!")
	
	# Connect the button signals
	p1_toggle.state_changed.connect(
		func(state): _on_toggle_changed(1, state))
	p2_toggle.state_changed.connect(
		func(state): _on_toggle_changed(2, state))
	confirm_button.pressed.connect(confirm_selection)
	
	# Set initial states
	p1_toggle.set_state("keyboard")
	p2_toggle.set_state("controller")
	
	# Check available controllers
	var connected_controllers = Input.get_connected_joypads()
	print("Available controllers for input selection: ", connected_controllers)
	
	# Warning if insufficient controllers
	if connected_controllers.size() < 1 and (p1_toggle.get_state() == "controller" or p2_toggle.get_state() == "controller"):
		print("WARNING: Controller selected but no controllers detected!")

func _on_toggle_changed(player: int, state: String):
	# No need to enforce specific restrictions anymore
	# Our new input system handles the keyboard schemes appropriately
	print("Player ", player, " input changed to: ", state)
	
	# Check if both players selected controller but only one is available
	var connected_controllers = Input.get_connected_joypads()
	if state == "controller" and p1_toggle.get_state() == "controller" and p2_toggle.get_state() == "controller" and connected_controllers.size() < 2:
		print("WARNING: Both players selected controller but only ", connected_controllers.size(), " controllers available")

func confirm_selection():
	print("Confirming selection")
	var p1_using_keyboard = p1_toggle.get_state() == "keyboard"
	var p2_using_keyboard = p2_toggle.get_state() == "keyboard"
	
	print("P1 using keyboard:", p1_using_keyboard)
	print("P2 using keyboard:", p2_using_keyboard)
	
	emit_signal("inputs_selected", p1_using_keyboard, p2_using_keyboard)
	hide()
