extends Node

var player_configs := {}
var previous_controller_states := {}

enum InputDevice { KEYBOARD, CONTROLLER }

# Separating movement and aim actions for clarity
const ACTIONS := {
	InputDevice.KEYBOARD: {
		"move": "get_keyboard_movement",
		"aim": "get_keyboard_aim",
		"fire": "keyboard_fire_pressed",
		"dash": "keyboard_dash_pressed"
	},
	InputDevice.CONTROLLER: {
		"move": "get_controller_movement",
		"aim": "get_controller_aim", 
		"fire": "controller_fire_pressed",
		"dash": "controller_dash_pressed"
	}
}

func _ready():
	print("\n=== Input Manager Initialization ===")
	print("Available controllers:", Input.get_connected_joypads())
	print("===================================\n")

func register_player(player_id: int, device: InputDevice, controller_id: int = -1):
	print("\n=== Registering Player ", player_id, " ===")
	print("Device type:", "Keyboard" if device == InputDevice.KEYBOARD else "Controller")
	print("Controller ID:", controller_id)
	
	player_configs[player_id] = {
		"device": device,
		"controller_id": controller_id
	}
	
	if device == InputDevice.CONTROLLER:
		print("Controller details:")
		print("  Name:", Input.get_joy_name(controller_id))
		print("  GUID:", Input.get_joy_guid(controller_id))
		print("  Axes:", Input.get_connected_joypads().size())
	
	print("Player ", player_id, " registration complete")
	print("Current player configs:", player_configs)
	print("=====================================\n")

# Separate movement and aim getters
func get_movement(player_id: int) -> Vector2:
	var config = player_configs.get(player_id)
	if not config:
		print("WARNING: No config found for player ", player_id, " in get_movement")
		return Vector2.ZERO
		
	var movement = call(ACTIONS[config.device].move, player_id)
	#if movement.length() > 0.1:  # Only log significant movement
		#print("Player ", player_id, " movement input - Device:", "Keyboard" if config.device == InputDevice.KEYBOARD else "Controller", " Value:", movement)
	return movement

func get_aim(player_id: int, player_position: Vector2 = Vector2.ZERO) -> Vector2:
	var config = player_configs.get(player_id)
	if not config:
		print("WARNING: No config found for player ", player_id, " in get_aim")
		return Vector2.RIGHT
		
	var aim_vector: Vector2
	if config.device == InputDevice.KEYBOARD:
		aim_vector = get_keyboard_aim(player_id, player_position)
	else:
		aim_vector = get_controller_aim(player_id)
	
	#if aim_vector.length() > 0.1:  # Only log significant aim changes
		#print("Player ", player_id, " aim input - Device:", "Keyboard" if config.device == InputDevice.KEYBOARD else "Controller", " Direction:", aim_vector)
	return aim_vector

# Movement implementations
func get_keyboard_movement(player_id: int) -> Vector2:
	var suffix = "_p2" if player_id == 1 else ""
	var movement = Vector2(
		float(Input.is_action_pressed("right" + suffix)) - float(Input.is_action_pressed("left" + suffix)),
		float(Input.is_action_pressed("down" + suffix)) - float(Input.is_action_pressed("up" + suffix))
	).normalized()
	
	#if movement.length() > 0:
		#print("Keyboard movement for Player ", player_id, ":")
		#print("  Suffix:", suffix)
		#print("  Raw input:", movement)
	return movement

func get_controller_movement(player_id: int) -> Vector2:
	var config = player_configs.get(player_id)
	if not config or config.controller_id == -1:
		print("WARNING: Invalid controller config for player ", player_id)
		return Vector2.ZERO
	
	# Left stick for movement
	var movement = Vector2(
		Input.get_joy_axis(config.controller_id, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(config.controller_id, JOY_AXIS_LEFT_Y)
	)
	
	#if movement.length() > 0.2:  # Only log when outside deadzone
		#print("Controller movement for Player ", player_id, ":")
		#print("  Controller ID:", config.controller_id)
		#print("  Left stick raw:", movement)
	return movement

# Aim implementations
func get_keyboard_aim(player_id: int, player_position: Vector2) -> Vector2:
	var mouse_pos = get_viewport().get_mouse_position()
	var aim = (mouse_pos - player_position).normalized()
	
	#if aim.length() > 0.1:
		#print("Keyboard aim for Player ", player_id, ":")
		#print("  Mouse position:", mouse_pos)
		#print("  Player position:", player_position)
		#print("  Aim vector:", aim)
	return aim

func get_controller_aim(player_id: int) -> Vector2:
	var config = player_configs.get(player_id)
	if not config or config.controller_id == -1:
		print("WARNING: Invalid controller config for player ", player_id)
		return Vector2.RIGHT
	
	# Right stick for aiming
	var aim = Vector2(
		Input.get_joy_axis(config.controller_id, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(config.controller_id, JOY_AXIS_RIGHT_Y)
	)
	
	#if aim.length() > 0.2:  # Only log when outside deadzone
		#print("Controller aim for Player ", player_id, ":")
		#print("  Controller ID:", config.controller_id)
		#print("  Right stick raw:", aim)
	
	# Return default direction if stick is in deadzone
	return aim if aim.length() > 0.2 else Vector2.ZERO

# Dash input implementations
func keyboard_dash_pressed(player_id: int) -> bool:
	var suffix = "_p2" if player_id == 1 else ""
	var is_pressed = Input.is_action_just_pressed("dash" + suffix)
	if is_pressed:
		print("Keyboard dash pressed for Player ", player_id)
	return is_pressed

func _process(_delta: float) -> void:
	# Update previous controller states at the end of each frame
	for player_id in player_configs:
		var config = player_configs.get(player_id)
		if config and config.device == InputDevice.CONTROLLER and config.controller_id != -1:
			if not previous_controller_states.has(player_id):
				previous_controller_states[player_id] = {}
			
			var current_state = Input.is_joy_button_pressed(config.controller_id, JOY_BUTTON_RIGHT_SHOULDER)
			var prev_state = previous_controller_states[player_id].get(JOY_BUTTON_RIGHT_SHOULDER, false)
			
			if current_state != prev_state:
				print("Controller button state changed for Player ", player_id, ":")
				print("  Button: Right Shoulder")
				print("  Previous state:", prev_state)
				print("  Current state:", current_state)
			
			previous_controller_states[player_id][JOY_BUTTON_RIGHT_SHOULDER] = current_state

func controller_dash_pressed(player_id: int) -> bool:
	var config = player_configs.get(player_id)
	if not config or config.controller_id == -1:
		return false
		
	# Initialize previous state if not exists
	if not previous_controller_states.has(player_id):
		previous_controller_states[player_id] = {}
	if not previous_controller_states[player_id].has(JOY_BUTTON_RIGHT_SHOULDER):
		previous_controller_states[player_id][JOY_BUTTON_RIGHT_SHOULDER] = false
		
	# Check if button is pressed now but wasn't pressed in the previous frame
	var current_state = Input.is_joy_button_pressed(config.controller_id, JOY_BUTTON_RIGHT_SHOULDER)
	var previous_state = previous_controller_states[player_id][JOY_BUTTON_RIGHT_SHOULDER]
	
	if current_state and not previous_state:
		print("Controller dash triggered for Player ", player_id, ":")
		print("  Controller ID:", config.controller_id)
		print("  Button: Right Shoulder")
	
	return current_state and not previous_state

# Generic dash check that works for both input types
func is_dash_pressed(player_id: int) -> bool:
	var config = player_configs.get(player_id)
	if not config:
		print("WARNING: No config found for player ", player_id, " in is_dash_pressed")
		return false
		
	return call(ACTIONS[config.device].dash, player_id)
