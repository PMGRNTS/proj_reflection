extends Button

# Define our states and their corresponding text
const STATES = {
	"keyboard": "KEYBOARD/MOUSE",
	"controller": "CONTROLLER"
}

# Track current state
var current_state: String = "keyboard"

# Signal to notify when state changes
signal state_changed(new_state: String)

func _ready():
	# Initialize button text
	text = STATES[current_state]
	
	# Connect to pressed signal
	pressed.connect(_on_toggle_pressed)

func _on_toggle_pressed():
	# Toggle between states
	current_state = "controller" if current_state == "keyboard" else "keyboard"
	
	# Update button text
	text = STATES[current_state]
	
	# Emit signal with new state
	emit_signal("state_changed", current_state)

# Public method to set state directly
func set_state(state: String) -> void:
	if state in STATES:
		current_state = state
		text = STATES[current_state]
		
# Public method to get current state
func get_state() -> String:
	return current_state
