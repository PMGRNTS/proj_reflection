extends Node

enum InputDevice { KEYBOARD, CONTROLLER }
enum KeyboardScheme { WASD, ARROWS }

# Player configurations
var player_devices = {
	0: InputDevice.KEYBOARD,  # Default values
	1: InputDevice.CONTROLLER
}

# Keyboard schemes when using keyboard
var player_keyboard_schemes = {
	0: KeyboardScheme.WASD,   # Default P1 uses WASD
	1: KeyboardScheme.ARROWS  # Default P2 uses arrows
}

# Controller IDs (if applicable)
var player_controller_ids = {
	0: -1,  # -1 means no controller
	1: 0    # First controller defaults to controller 0
}

# For tracking previous controller states (for button press detection)
var previous_controller_states = {}
var previous_trigger_values = {}

# Keyboard key mappings for the two keyboard schemes
const KEYBOARD_MAPPINGS = {
	KeyboardScheme.WASD: {
		"up": KEY_W,
		"down": KEY_S,
		"left": KEY_A,
		"right": KEY_D,
		"fire": KEY_SPACE,
		"dash": KEY_SHIFT,
		"reflect": KEY_Q
	},
	KeyboardScheme.ARROWS: {
		"up": KEY_UP,
		"down": KEY_DOWN,
		"left": KEY_LEFT,
		"right": KEY_RIGHT,
		"fire": KEY_CTRL,
		"dash": KEY_SHIFT,
		"reflect": KEY_PERIOD
	}
}

# Controller button mappings
const CONTROLLER_MAPPINGS = {
	"dash": JOY_BUTTON_RIGHT_SHOULDER,
	"reflect": JOY_BUTTON_LEFT_SHOULDER
}

# Trigger threshold for firing
const TRIGGER_THRESHOLD = 0.6

func _ready():
	print("\n=== Input Manager Initialization ===")
	print("Available controllers:", Input.get_connected_joypads())
	
	# Initialize controller tracking
	for controller_id in Input.get_connected_joypads():
		previous_controller_states[controller_id] = {}
		previous_trigger_values[controller_id] = 0.0
	
	print("===================================\n")

func register_player(player_id: int, device: InputDevice, controller_id: int = -1):
	print("\n=== Registering Player ", player_id, " ===")
	player_devices[player_id] = device
	
	if device == InputDevice.KEYBOARD:
		# When setting a player to keyboard, make sure we assign them a different scheme
		# than any other player using keyboard
		var keyboard_scheme = KeyboardScheme.WASD
		
		# Find if another player is using keyboard and which scheme they're using
		for other_id in player_devices:
			if other_id != player_id and player_devices[other_id] == InputDevice.KEYBOARD:
				# Other player is using keyboard, so use the alternate scheme
				keyboard_scheme = KeyboardScheme.ARROWS if player_keyboard_schemes[other_id] == KeyboardScheme.WASD else KeyboardScheme.WASD
				break
				
		player_keyboard_schemes[player_id] = keyboard_scheme
		print("  Using keyboard scheme:", "WASD" if keyboard_scheme == KeyboardScheme.WASD else "Arrows")
		player_controller_ids[player_id] = -1
	else:
		player_controller_ids[player_id] = controller_id
		print("  Using controller ID:", controller_id)
		if controller_id >= 0 and controller_id < Input.get_connected_joypads().size():
			print("  Controller name:", Input.get_joy_name(controller_id))
	
	print("Player ", player_id, " registration complete")
	print("===================================\n")

func _process(delta):
	# Update previous controller states at the end of each frame
	for controller_id in Input.get_connected_joypads():
		if not previous_controller_states.has(controller_id):
			previous_controller_states[controller_id] = {}
		if not previous_trigger_values.has(controller_id):
			previous_trigger_values[controller_id] = 0.0
			
		# Track all controller buttons we need
		for button in [CONTROLLER_MAPPINGS.dash, CONTROLLER_MAPPINGS.reflect]:
			previous_controller_states[controller_id][button] = Input.is_joy_button_pressed(controller_id, button)
		
		# Track right trigger value for firing
		previous_trigger_values[controller_id] = Input.get_joy_axis(controller_id, JOY_AXIS_TRIGGER_RIGHT)

# === Movement input ===
func get_movement(player_id: int) -> Vector2:
	if not player_devices.has(player_id):
		print("WARNING: Player ID not registered: ", player_id)
		return Vector2.ZERO
		
	if player_devices[player_id] == InputDevice.KEYBOARD:
		var scheme = player_keyboard_schemes[player_id]
		return Vector2(
			float(Input.is_key_pressed(KEYBOARD_MAPPINGS[scheme].right)) - 
			float(Input.is_key_pressed(KEYBOARD_MAPPINGS[scheme].left)),
			float(Input.is_key_pressed(KEYBOARD_MAPPINGS[scheme].down)) - 
			float(Input.is_key_pressed(KEYBOARD_MAPPINGS[scheme].up))
		).normalized()
	else:
		var controller_id = player_controller_ids[player_id]
		if controller_id >= 0:
			# Get left stick input
			var x = Input.get_joy_axis(controller_id, JOY_AXIS_LEFT_X)
			var y = Input.get_joy_axis(controller_id, JOY_AXIS_LEFT_Y)
			
			# Apply deadzone
			var movement = Vector2(x, y)
			if movement.length() < 0.15:  # Deadzone threshold
				return Vector2.ZERO
			return movement
		return Vector2.ZERO

# === Aim input ===
func get_aim(player_id: int, player_position: Vector2) -> Vector2:
	if not player_devices.has(player_id):
		print("WARNING: Player ID not registered: ", player_id)
		return Vector2.RIGHT
		
	if player_devices[player_id] == InputDevice.KEYBOARD:
		# Mouse aim for keyboard players
		var mouse_pos = get_viewport().get_mouse_position()
		return (mouse_pos - player_position).normalized()
	else:
		var controller_id = player_controller_ids[player_id]
		if controller_id >= 0:
			# Get right stick input
			var x = Input.get_joy_axis(controller_id, JOY_AXIS_RIGHT_X)
			var y = Input.get_joy_axis(controller_id, JOY_AXIS_RIGHT_Y)
			
			# Apply deadzone
			var aim = Vector2(x, y)
			if aim.length() < 0.15:  # Deadzone threshold
				return Vector2.ZERO
			return aim
		return Vector2.ZERO

# === Fire input ===
func is_fire_pressed(player_id: int) -> bool:
	if not player_devices.has(player_id):
		print("WARNING: Player ID not registered: ", player_id)
		return false
		
	if player_devices[player_id] == InputDevice.KEYBOARD:
		var scheme = player_keyboard_schemes[player_id]
		return Input.is_key_pressed(KEYBOARD_MAPPINGS[scheme].fire)
	else:
		var controller_id = player_controller_ids[player_id]
		if controller_id >= 0:
			# Check right trigger for fire
			var current_trigger = Input.get_joy_axis(controller_id, JOY_AXIS_TRIGGER_RIGHT)
			var previous_trigger = previous_trigger_values[controller_id]
			
			# Return true if trigger just crossed the threshold (rising edge detection)
			return current_trigger >= TRIGGER_THRESHOLD and previous_trigger < TRIGGER_THRESHOLD
		return false

# === Dash input ===
func is_dash_pressed(player_id: int) -> bool:
	if not player_devices.has(player_id):
		print("WARNING: Player ID not registered: ", player_id)
		return false
		
	if player_devices[player_id] == InputDevice.KEYBOARD:
		var scheme = player_keyboard_schemes[player_id]
		return Input.is_key_pressed(KEYBOARD_MAPPINGS[scheme].dash)
	else:
		var controller_id = player_controller_ids[player_id]
		if controller_id >= 0:
			var button = CONTROLLER_MAPPINGS.dash
			var current = Input.is_joy_button_pressed(controller_id, button)
			var previous = previous_controller_states[controller_id].get(button, false)
			
			# Check for button press (was up, now down)
			return current and not previous
		return false

# === Reflect input ===
func is_reflect_pressed(player_id: int) -> bool:
	if not player_devices.has(player_id):
		print("WARNING: Player ID not registered: ", player_id)
		return false
		
	if player_devices[player_id] == InputDevice.KEYBOARD:
		var scheme = player_keyboard_schemes[player_id]
		return Input.is_key_pressed(KEYBOARD_MAPPINGS[scheme].reflect)
	else:
		var controller_id = player_controller_ids[player_id]
		if controller_id >= 0:
			var button = CONTROLLER_MAPPINGS.reflect
			var current = Input.is_joy_button_pressed(controller_id, button)
			var previous = previous_controller_states[controller_id].get(button, false)
			
			# Check for button press (was up, now down)
			return current and not previous
		return false
