extends Node

var player_configs := {}

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

func register_player(player_id: int, device: InputDevice, controller_id: int = -1):
	player_configs[player_id] = {
		"device": device,
		"controller_id": controller_id
	}
	print("Registered player ", player_id, " with device: ", device, " controller_id: ", controller_id)

# Separate movement and aim getters
func get_movement(player_id: int) -> Vector2:
	var config = player_configs.get(player_id)
	if not config:
		return Vector2.ZERO
		
	return call(ACTIONS[config.device].move, player_id)

func get_aim(player_id: int) -> Vector2:
	var config = player_configs.get(player_id)
	if not config:
		return Vector2.RIGHT
		
	return call(ACTIONS[config.device].aim, player_id)

# Movement implementations
func get_keyboard_movement(player_id: int) -> Vector2:
	var suffix = "_p2" if player_id == 1 else ""
	return Vector2(
		float(Input.is_action_pressed("right" + suffix)) - float(Input.is_action_pressed("left" + suffix)),
		float(Input.is_action_pressed("down" + suffix)) - float(Input.is_action_pressed("up" + suffix))
	).normalized()

func get_controller_movement(player_id: int) -> Vector2:
	var config = player_configs.get(player_id)
	if not config or config.controller_id == -1:
		return Vector2.ZERO
	
	# Left stick for movement
	return Vector2(
		Input.get_joy_axis(config.controller_id, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(config.controller_id, JOY_AXIS_LEFT_Y)
	)

# Aim implementations
func get_keyboard_aim(player_id: int, player_position: Vector2) -> Vector2:
	# Calculate aim direction from player position to mouse position
	return (get_viewport().get_mouse_position() - player_position).normalized()


func get_controller_aim(player_id: int) -> Vector2:
	var config = player_configs.get(player_id)
	if not config or config.controller_id == -1:
		return Vector2.RIGHT
	
	# Right stick for aiming
	var aim = Vector2(
		Input.get_joy_axis(config.controller_id, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(config.controller_id, JOY_AXIS_RIGHT_Y)
	)
	
	# Return default direction if stick is in deadzone
	return aim if aim.length() > 0.2 else Vector2.RIGHT
