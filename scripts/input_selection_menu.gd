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
	
	# Set up signals
	p1_toggle.state_changed.connect(
		func(state): _on_toggle_changed(1, state))
	p2_toggle.state_changed.connect(
		func(state): _on_toggle_changed(2, state))
	confirm_button.pressed.connect(confirm_selection)
	
	# Set initial states
	p1_toggle.set_state("keyboard")
	p2_toggle.set_state("controller")

func _on_toggle_changed(player: int, state: String):
	if state == "keyboard":
		if player == 1:
			p2_toggle.set_state("controller")
		else:
			p1_toggle.set_state("controller")

func confirm_selection():
	print("Confirming selection")
	print("P1 using keyboard:", p1_toggle.get_state() == "keyboard")
	print("P2 using keyboard:", p2_toggle.get_state() == "keyboard")
	emit_signal("inputs_selected", 
		p1_toggle.get_state() == "keyboard",
		p2_toggle.get_state() == "keyboard")
	hide()
