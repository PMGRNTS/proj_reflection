extends CharacterBody2D

signal player_hit(player_index: int)

# Exported Variables
@export var player_color := Color("4b9cff") # Default blue for P1

@export var speed = 200
@export var accel = 1300
@export var dash_speed = 1200  # Reduced for better control
@export var dash_duration = 0.2  # Increased slightly for more noticeable effect
@export var dash_cooldown_time = 0.8  # Reduced to make dash feel more responsive
@export var dash_distance := 200.0  # Increased to make dash more impactful
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
var debug_ray_line: Line2D  # To visualize raycast direction
var look_direction = Vector2.RIGHT  # Default look direction
var last_aim_direction = Vector2.RIGHT  # Store last valid aim
var is_dashing = false
var can_dash = true
var dash_target := Vector2.ZERO

var can_fire := true
var time_passed := 0.0  # Used for our sine wave effect
var trail_points: Array[Vector2] = []
var laser_line: Line2D

var hit_freeze_frames := 0

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
	
	print("\n=== Player ", player_index, " Initialization ===")
	# Now set up with correct index
	if player_index == 0:
		player_color = Color("4b9cff")  # P1 is blue
	else:
		player_color = Color("ff4b4b")  # P2 is red
	
	print("Player ", player_index, " initialized with index-specific settings")
	print("Input suffix: ", input_suffix)
	print("Player", player_index, "color set to:", player_color)
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
	laser_line.width = 6.0
	laser_line.default_color = player_color  # Use player's color for laser
	
	# Setup raycast for laser
	laser_raycast.target_position = Vector2.RIGHT * laser_range
	laser_raycast.collision_mask = 1  # Adjust based on your collision layers
	
	print("=== Player ", player_index, " Setup Complete ===")
	print("Initial position:", global_position)
	print("Initial look direction:", look_direction)
	print("\n")
	

func _process(_delta):
	time_passed += _delta * 10.0
	debug_ray_line.rotation = reflect_area.rotation
	
	# Update trail positions
	trail_points.pop_back()
	trail_points.push_front(global_position)
	
	# Update both trails with current positions
	main_trail.clear_points()
	shadow_trail.clear_points()
	if hit_freeze_frames > 0:
		hit_freeze_frames -= 1
		return
		
	# Add points with a slight offset for shadow trail
	for i in trail_points.size():
		var point = trail_points[i]
		var local_point = to_local(point)
		main_trail.add_point(local_point)
		# Offset shadow trail slightly based on movement
		shadow_trail.add_point(local_point + velocity.normalized() * -4)
		
	# Make trails more pronounced during dash
	if is_dashing:
		main_trail.width = trail_width * 2.5  # Much wider during dash
		shadow_trail.width = trail_width * 3.5  # Much wider shadow
		main_trail.default_color = Color(1, 1, 1, 1.0)  # Pure white, fully opaque
		shadow_trail.default_color = player_color.lightened(0.3)  # Brighter player color
	else:
		main_trail.width = trail_width
		shadow_trail.width = trail_width * 1.5
		main_trail.default_color = trail_color
		shadow_trail.default_color = shadow_color

func _setup_trails():
	print("Setting up trails for Player ", player_index)
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
	print("Trail setup complete - Main trail width:", trail_width, " Shadow trail width:", trail_width * 1.5)

func start_dash():
	if can_dash:
		dash_target = global_position + (look_direction * dash_distance)
		print("\n=== Player ", player_index, " Dash Started ===")
		print("Starting position:", global_position)
		print("Dash target:", dash_target)
		print("Look direction:", look_direction)
		print("Dash distance:", dash_distance)
		is_dashing = true
		can_dash = false
		dash_cooldown.start()
		dash_dur.start()

func _physics_process(delta: float) -> void:
	if is_dashing:
		# Use look_direction directly for consistent dash direction
		velocity = look_direction * dash_speed
		move_and_slide()
		
		var distance_to_target = global_position.distance_to(dash_target)
		print("Player ", player_index, " dashing - Distance to target:", distance_to_target, " Current velocity:", velocity)
		
		if distance_to_target <= 5:
			print("Player ", player_index, " dash complete at position:", global_position)
			is_dashing = false
			velocity = Vector2.ZERO
			global_position = dash_target
	else:
		# Handle regular movement
		var raw_movement = InputManager.get_movement(player_index)
		velocity = raw_movement * speed
		move_and_slide()
	
	var new_aim = InputManager.get_aim(player_index, global_position)
	if new_aim.length_squared() > 0.04:  # Using squared length for efficiency
		last_aim_direction = new_aim
		look_direction = new_aim
		var new_rotation = new_aim.angle()
		reflect_area.rotation = new_rotation
		laser_raycast.rotation = new_rotation  # Keep raycast aligned with aim direction
		#print("Player ", player_index, " aim updated - Direction:", new_aim, " Rotation:", new_rotation)

	# Check for dash input
	if InputManager.is_dash_pressed(player_index) and can_dash:
		start_dash()
	

func _input(event: InputEvent) -> void:
	# Handle non-movement input events
	if event.is_action_pressed("reflect" + input_suffix):
		print("\n=== Player ", player_index, " Reflection Started ===")
		print("Reflection rotation:", reflect_area.rotation)
		print("Player position:", global_position)
		$ReflectArea/Hitbox.disabled = false
		$ReflectArea/Sprite.visible = true
		await get_tree().create_timer(0.2).timeout
		$ReflectArea/Hitbox.disabled = true
		$ReflectArea/Sprite.visible = false
		print("Player ", player_index, " reflection ended")
	elif event.is_action_pressed("fire" + input_suffix):
		print("\n=== Player ", player_index, " Fire Attempt ===")
		fire_laser()

func _on_dash_cooldown_timeout():
	can_dash = true
	print("Player ", player_index, " dash cooldown complete - Can dash again")

func _on_dash_dur_timeout() -> void:
	# Only end dash if we haven't reached target yet
	if is_dashing and global_position.distance_to(dash_target) > 5:
		is_dashing = false
		velocity = Vector2.ZERO
		print("Player ", player_index, " dash duration ended")

func fire_laser():
	if !can_fire:
		print("Player ", player_index, " attempted to fire but on cooldown")
		return
		
	print("\n=== Player ", player_index, " Firing Laser ===")
	can_fire = false
	fire_cooldown.start()
	
	# Update raycast direction and visualize it
	#laser_raycast.rotation = reflect_area.rotation
	laser_line.clear_points()
	laser_line.add_point(Vector2.ZERO)
	
		# Visual feedback for firing
	$Sprite.scale = Vector2(1.8, 1.8)  # Brief scaling effect
	var recoil_tween = create_tween()
	recoil_tween.tween_property($Sprite, "scale", Vector2(1.5, 1.5), 0.2)
	
	print("Firing laser - Position:", global_position, " Rotation:", laser_raycast.rotation)
	laser_raycast.force_raycast_update()
	# Check for collision
	if laser_raycast.is_colliding():
		var collision_point = to_local(laser_raycast.get_collision_point())
		laser_line.add_point(collision_point)
		print("Laser hit at:", collision_point)
		
		var hit_object = laser_raycast.get_collider()
		if hit_object is CharacterBody2D and hit_object != self:
			print("Hit valid target:", hit_object.name)
			if hit_object.has_method("take_damage"):
				hit_object.take_damage(laser_damage)
				print("Applied ", laser_damage, " damage to target")
	else:
		# No collision, draw to max range
		var end_point = Vector2.RIGHT.rotated(laser_raycast.rotation) * laser_range
		laser_line.add_point(end_point)
		print("Laser missed, ending at:", end_point)
	
	# Make laser fade out instead of disappearing
	var fade_tween = create_tween()
	fade_tween.tween_property(laser_line, "modulate:a", 0.0, 0.3)
	await fade_tween.finished
	laser_line.clear_points()
	laser_line.modulate.a = 1.0

func take_damage(damage: int):
	# No need for HP tracking
	# var old_hp = current_hp
	# current_hp -= damage
	
	# Visual feedback
	var flash_tween = create_tween()
	flash_tween.tween_property($Sprite, "modulate", Color.WHITE, 0.05)
	flash_tween.tween_property($Sprite, "modulate", player_color, 0.05)
	
	# Add more visual juice
	if JuiceManager:
		JuiceManager.player_hit_effect(global_position, player_color)
	
	# Player was hit - emit signal immediately
	print("Player ", player_index, " was hit!")
	emit_signal("player_hit", player_index)
	
func _on_fire_cooldown_timeout():
	can_fire = true
	print("Player ", player_index, " laser cooldown complete - Can fire again")

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
