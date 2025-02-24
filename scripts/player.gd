extends CharacterBody2D

signal player_hit(player_index: int)

# Exported Variables
@export var player_color := Color("4b9cff") # Default blue for P1
@export var max_hp = 150
@export var speed = 200
@export var accel = 1300
@export var dash_speed = 2000
@export var dash_duration = 0.08
@export var dash_cooldown_time = 1.0
@export var dash_distance := 150.0  # Distance to dash in pixels
@export var controller_aim_speed := 5.0  # Speed multiplier for controller aim rotation
@export var player_index := 0  # 0 for P1, 1 for P2
@export var trail_length := 20  # More points = longer trail
@export var trail_width := 15.0
@export var trail_color := Color(0.9, 0.9, 1.0, 0.8)  # Slightly transparent white
@export var shadow_color := Color(0.2, 0.4, 0.8, 0.4)  # Ethereal blue shadow
@export var laser_range := 1000.0
@export var laser_damage := 35
@export var fire_rate := 0.75  # Time between shots in seconds

# Regular Variables
var using_keyboard := false
var debug_ray_line: Line2D  # To visualize raycast direction
var current_hp = max_hp
var look_direction = Vector2.ZERO
var is_dashing = false
var can_dash = true
var dash_target := Vector2.ZERO
var aim_angle := 0.0  # Track rotation angle for controller aim
var can_fire := true
var time_passed := 0.0  # Used for our sine wave effect
var trail_points: Array[Vector2] = []
var laser_line: Line2D

# Onready Variables (Node References)
@onready var dash_dur = $DashDur
@onready var dash_cooldown = $DashCooldown
@onready var reflect_area = $ReflectArea
@onready var reflect_hitbox = $ReflectArea/Hitbox
@onready var laser_raycast := $LaserRaycast
@onready var fire_cooldown := $FireCooldown
@onready var main_trail := $MainTrail
@onready var shadow_trail := $ShadowTrail


var input_suffix: String:
	get:
		# Change this from current version
		# return "_p2" if player_index == 1 else ""
		
		# To explicitly set suffix when index changes
		if player_index == 0:
			return ""
		else:
			return "_p2"

func _ready():
	await get_tree().process_frame
	
	# Now set up with correct index
	if player_index == 0:
		player_color = Color("4b9cff")  # P1 is blue
	else:
		player_color = Color("ff4b4b")  # P2 is red
	
	print("Player ", player_index, " initialized with index-specific settings")
	print("Using keyboard: ", using_keyboard)
	print("Input suffix: ", input_suffix)
	print("Player", player_index, "color set to:", player_color)
	print("Player ", player_index, " initialized with keyboard: ", using_keyboard)
	print("Available controllers: ", Input.get_connected_joypads())
	# Add debug raycast line
	debug_ray_line = Line2D.new()
	add_child(debug_ray_line)
	debug_ray_line.width = 1.0
	debug_ray_line.default_color = Color.YELLOW
	debug_ray_line.add_point(Vector2.ZERO)
	debug_ray_line.add_point(Vector2(50, 0))  # Shows aim direction
	
	# Now set up visual elements with the correct color
	$Sprite.modulate = player_color
	
	# Initialize trail colors based on player color
	trail_color = player_color
	shadow_color = player_color.darkened(0.5)
	shadow_color.a = 0.4
	
	# Previous initialization code
	for i in trail_length:
		trail_points.append(position)
	
	_setup_trails()
	
	# Set up dash timers
	dash_dur.wait_time = dash_duration
	dash_dur.one_shot = true
	dash_cooldown.wait_time = dash_cooldown_time
	dash_cooldown.one_shot = true
	
	# Setup laser cooldown timer
	fire_cooldown.wait_time = fire_rate
	fire_cooldown.one_shot = true
	fire_cooldown.timeout.connect(_on_fire_cooldown_timeout)
	
	# Setup laser line with player color
	laser_line = Line2D.new()
	add_child(laser_line)
	laser_line.width = 2.0
	laser_line.default_color = player_color  # Use player's color for laser
	
	# Setup raycast for laser
	laser_raycast.target_position = Vector2.RIGHT * laser_range
	laser_raycast.collision_mask = 1  # Adjust based on your collision layers
	
	# Debug print to verify setup
	print("Player ", player_index, " using keyboard: ", using_keyboard, " color: ", player_color)

	
func _process(delta):
	time_passed += delta * 10.0
	debug_ray_line.rotation = reflect_area.rotation
	# Update trail positions
	trail_points.pop_back()
	trail_points.push_front(global_position)
	
	# Update both trails with current positions
	main_trail.clear_points()
	shadow_trail.clear_points()
	
	# Input handling - simplified and more explicit
	if using_keyboard:
		# Mouse aim for keyboard player
		look_direction = (get_global_mouse_position() - position).normalized()
		reflect_area.look_at(get_global_mouse_position())
	else:
		# Controller aim
		_handle_controller_aim(delta)

		
	# Add points with a slight offset for shadow trail
	for i in trail_points.size():
		var point = trail_points[i]
		var local_point = to_local(point)
		main_trail.add_point(local_point)
		# Offset shadow trail slightly based on movement
		shadow_trail.add_point(local_point + velocity.normalized() * -4)

		
	# Make trails more pronounced during dash
	if is_dashing:
		main_trail.width = trail_width * 1.5
		shadow_trail.width = trail_width * 2
		main_trail.default_color = Color(1, 1, 1, 0.9)  # Brighter white
		shadow_trail.default_color = Color(0.4, 0.6, 1.0, 0.6)  # Brighter blue

	else:
		main_trail.width = trail_width
		shadow_trail.width = trail_width * 2.5
		main_trail.default_color = trail_color
		shadow_trail.default_color = shadow_color

func _physics_process(delta: float) -> void:
	# Handle movement
	velocity = InputManager.get_movement(player_index) * speed
	move_and_slide()
	
	# Get the player's input configuration
	var config = InputManager.player_configs.get(player_index)
	if not config:
		return
		
	# Handle aim based on input device
	var aim_direction: Vector2
	if config.device == InputManager.InputDevice.KEYBOARD:
		aim_direction = InputManager.get_keyboard_aim(player_index, global_position)
	else:
		aim_direction = InputManager.get_controller_aim(player_index)
	
	# Only update aim if we got valid input
	if aim_direction != Vector2.ZERO:
		look_direction = aim_direction
		reflect_area.rotation = aim_direction.angle()
	
	if is_dashing:
		var distance_to_target = global_position.distance_to(dash_target)
		if distance_to_target > 5:
			velocity = global_position.direction_to(dash_target) * dash_speed
		else:
			is_dashing = false
			velocity = Vector2.ZERO
			global_position = dash_target


func get_input_axis() -> Vector2:
	var axis = Vector2.ZERO
	
	if using_keyboard:
		# Keyboard movement
		axis.x = int(Input.is_action_pressed("right" + input_suffix)) - int(Input.is_action_pressed("left" + input_suffix))
		axis.y = int(Input.is_action_pressed("down" + input_suffix)) - int(Input.is_action_pressed("up" + input_suffix))
	else:
		# Controller movement
		# Get the first connected controller if we're player 2, or second if we're player 1 using controller
		var controller_id = player_index
		if Input.get_connected_joypads().size() > controller_id:
			axis = Vector2(
				Input.get_joy_axis(Input.get_connected_joypads()[controller_id], JOY_AXIS_LEFT_X),
				Input.get_joy_axis(Input.get_connected_joypads()[controller_id], JOY_AXIS_LEFT_Y)
			)
		# Apply deadzone
		if axis.length() < 0.2:
			axis = Vector2.ZERO
	return axis

func _setup_trails():
	# Set up main white trail
	main_trail.width = trail_width
	main_trail.width_curve = _create_width_curve()
	main_trail.default_color = trail_color
	main_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	main_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	main_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	# Set up shadow trail (slightly wider, different color)
	shadow_trail.width = trail_width * 1.5
	shadow_trail.width_curve = _create_width_curve()
	shadow_trail.default_color = shadow_color
	shadow_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	shadow_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shadow_trail.end_cap_mode = Line2D.LINE_CAP_ROUND

func _handle_controller_aim(delta: float) -> void:
	# Get right stick input
	var aim_input := Vector2(
		Input.get_joy_axis(player_index, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(player_index, JOY_AXIS_RIGHT_Y)
	)
	
	# Apply deadzone
	if aim_input.length() < 0.2:
		return
	
	# Update aim angle based on stick input
	aim_angle = aim_input.angle()
	reflect_area.rotation = aim_angle
	look_direction = Vector2.RIGHT.rotated(aim_angle)


func start_dash():
	if can_dash:
		dash_target = global_position + (look_direction * dash_distance)
		is_dashing = true
		can_dash = false
		dash_cooldown.start()
		# Add the duration timer back
		dash_dur.start()


func _input(event):
	# Handle both controller and keyboard/mouse input for actions
	if (event.is_action_pressed("dash" + input_suffix) or 
		(event is InputEventJoypadButton and 
		event.button_index == JOY_BUTTON_RIGHT_SHOULDER and
		event.pressed and 
		event.device == player_index)) and can_dash:
		start_dash()
	elif (event.is_action_pressed("reflect" + input_suffix) or
		(event is InputEventJoypadButton and 
		event.button_index == JOY_BUTTON_LEFT_SHOULDER and
		event.pressed and 
		event.device == player_index)):
		$ReflectArea/Hitbox.disabled = false
		$ReflectArea/Sprite.visible = true
		await get_tree().create_timer(0.2).timeout
		$ReflectArea/Hitbox.disabled = true
		$ReflectArea/Sprite.visible = false
	elif (event.is_action_pressed("fire" + input_suffix) or
		(event is InputEventJoypadButton and 
		event.button_index == JOY_BUTTON_A and  # A/Cross button for firing
		event.pressed and 
		event.device == player_index)):
		fire_laser()

func _on_dash_cooldown_timeout():
	can_dash = true

func _on_dash_dur_timeout() -> void:
	is_dashing = false
	velocity = Vector2.ZERO



func fire_laser():
	if !can_fire:
		return
		
	can_fire = false
	fire_cooldown.start()
	
	# Update raycast direction and visualize it
	laser_raycast.rotation = reflect_area.rotation
	laser_line.clear_points()
	laser_line.add_point(Vector2.ZERO)
	
	print("Firing laser for player", player_index, "at rotation:", laser_raycast.rotation)
	
	# Check for collision
	if laser_raycast.is_colliding():
		var collision_point = to_local(laser_raycast.get_collision_point())
		laser_line.add_point(collision_point)
		print("Laser hit at:", collision_point)
		
		var hit_object = laser_raycast.get_collider()
		if hit_object is CharacterBody2D and hit_object != self:
			if hit_object.has_method("take_damage"):
				hit_object.take_damage(laser_damage)
	else:
		# No collision, draw to max range
		var end_point = Vector2.RIGHT.rotated(laser_raycast.rotation) * laser_range
		laser_line.add_point(end_point)
		print("Laser missed, ending at:", end_point)
	
	# Make laser disappear after a short time
	await get_tree().create_timer(0.1).timeout
	laser_line.clear_points()

func take_damage(damage: int):
	current_hp -= damage
	if current_hp <= 0:
		# We've been defeated
		emit_signal("player_hit", player_index)  # This is where we emit the signal!

func _on_fire_cooldown_timeout():
	can_fire = true


func _create_width_curve() -> Curve:
	var curve = Curve.new()
	# Start wide at the player
	curve.add_point(Vector2(0, 1), 0, -0.5)
	# Add a subtle pulse in the middle
	curve.add_point(Vector2(0.3, 0.8), 0, 0)
	curve.add_point(Vector2(0.6, 0.5), 0, 0)
	# Fade to nothing at the end
	curve.add_point(Vector2(1, 0), -1, 0)
	return curve
