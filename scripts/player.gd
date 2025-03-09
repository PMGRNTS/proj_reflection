extends CharacterBody2D

signal player_hit(player_index: int)

# Exported Variables
@export var player_color := Color("4b9cff") # Default blue for P1

@export var speed = 300
@export var accel = 1300
@export var dash_speed = 6000  # Reduced for better control
@export var dash_duration = 0.05  # Increased slightly for more noticeable effect
@export var dash_cooldown_time = 0.8  # Reduced to make dash feel more responsive
@export var dash_distance := 200.0  # Increased to make dash more impactful
@export var player_index := 0  # 0 for P1, 1 for P2
@export var trail_length := 20  # More points = longer trail
@export var trail_width := 24.0
@export var trail_color := Color(0.9, 0.9, 1.0, 0.8)  # Slightly transparent white
@export var shadow_color := Color(0.2, 0.4, 0.8, 0.4)  # Ethereal blue shadow
@export var laser_range := 1000.0
@export var laser_damage := 35
@export var fire_rate := 0.75  # Time between shots in seconds
@export var reflect_duration := 0.7  # Increased duration to make reflection easier

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
var hit_freeze_frames := 0
var is_reflecting := false

# Onready Variables (Node References)
@onready var dash_dur = $DashDur
@onready var dash_cooldown = $DashCooldown
@onready var reflect_area = $ReflectArea
@onready var reflect_hitbox = $ReflectArea/Hitbox
@onready var laser_raycast := $LaserRaycast
@onready var fire_cooldown := $FireCooldown
@onready var main_trail := $MainTrail
@onready var shadow_trail := $ShadowTrail

func _ready():
	await get_tree().process_frame
	
	print("\n=== Player ", player_index, " Initialization ===")
	# Now set up with correct index
	if player_index == 0:
		player_color = Color("4b9cff")  # P1 is blue
	else:
		player_color = Color("ff4b4b")  # P2 is red
	
	print("Player ", player_index, " initialized with index-specific settings")
	print("Player", player_index, "color set to:", player_color)
	print("Available controllers: ", Input.get_connected_joypads())
	
	# Add debug raycast line || THIS BASICALLY BECAUSE A PIECE OF THE HUD
	debug_ray_line = Line2D.new()
	add_child(debug_ray_line)
	debug_ray_line.width = 2.0
	debug_ray_line.default_color = Color.FLORAL_WHITE
	debug_ray_line.add_point(Vector2(40,0))
	debug_ray_line.add_point(Vector2(60, 0))  # Shows aim direction
	
	# Now set up visual elements with the correct color
	$Sprite.modulate = player_color
	
	# Initialize trail colors based on player color
	trail_color = player_color
	shadow_color = player_color.darkened(0.5)
	shadow_color.a = 0.4
	
	# Initialize trails
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
	
	# Setup raycast for laser
	laser_raycast.target_position = Vector2.RIGHT * laser_range
	laser_raycast.collision_mask = 1  # Adjust based on your collision layers
	
	# Initialize reflection state
	reflect_area.get_node("Hitbox").disabled = true
	reflect_area.get_node("Sprite").visible = false
	
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
		shadow_trail.add_point(local_point + velocity.normalized() * -9)#-4
		
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

func _physics_process(delta: float) -> void:
	if hit_freeze_frames > 0:
		return
		
	if is_dashing:
		# Use look_direction directly for consistent dash direction
		velocity = look_direction * dash_speed
		move_and_slide()
		
		var distance_to_target = global_position.distance_to(dash_target)
		
		if distance_to_target <= 5:
			is_dashing = false
			velocity = Vector2.ZERO
			global_position = dash_target
	else:
		# Use the new input manager for movement
		var raw_movement = InputManager.get_movement(player_index)
		velocity = raw_movement * speed
		move_and_slide()
	
	# Handle aim
	var new_aim = InputManager.get_aim(player_index, global_position)
	if new_aim.length_squared() > 0.04:  # Using squared length for efficiency
		last_aim_direction = new_aim
		look_direction = new_aim
		var new_rotation = new_aim.angle()
		reflect_area.rotation = new_rotation
		laser_raycast.rotation = new_rotation  # Keep raycast aligned with aim direction

	# Check for dash input
	if InputManager.is_dash_pressed(player_index) and can_dash:
		start_dash()
	
	# Check for fire input
	if InputManager.is_fire_pressed(player_index) and can_fire:
		fire_laser()
	
	# Check for reflect input
	if InputManager.is_reflect_pressed(player_index) and not is_reflecting:
		activate_reflect()

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
		
		# Play dash sound
		AudioManager.play_sound("dash")

func activate_reflect():
	print("\n=== Player ", player_index, " Reflection Started ===")
	print("Reflection rotation:", reflect_area.rotation)
	print("Player position:", global_position)
	is_reflecting = true
	reflect_hitbox.disabled = false
	reflect_area.get_node("Sprite").visible = true
	
	# Play reflection activation sound
	AudioManager.play_sound("reflect_up")
	
	# Flash effect to indicate reflection
	var flash_tween = create_tween()
	flash_tween.tween_property($Sprite, "modulate", Color.WHITE, 0.1)
	flash_tween.tween_property($Sprite, "modulate", player_color, 0.1)
	
	# Increase reflect duration for easier use
	await get_tree().create_timer(reflect_duration).timeout
	
	reflect_hitbox.disabled = true
	reflect_area.get_node("Sprite").visible = false
	is_reflecting = false
	print("Player ", player_index, " reflection ended")

func fire_laser():
	if !can_fire:
		print("Player ", player_index, " attempted to fire but on cooldown")
		return
		
	print("\n=== Player ", player_index, " Firing Laser ===")
	can_fire = false
	fire_cooldown.start()
	
	# Play firing sound
	AudioManager.play_sound("fire")
	
	# Store original scale for recoil effect
	var original_scale = $Sprite.scale
	
	# Visual feedback for firing - scale up slightly
	$Sprite.scale = original_scale * 1.2  # 20% bigger for recoil
	var recoil_tween = create_tween()
	recoil_tween.tween_property($Sprite, "scale", original_scale, 0.2)  # Return to original
	
	# Create a new laser node in the world
	var laser = Node2D.new()
	get_tree().root.add_child(laser)
	laser.global_position = global_position
	laser.rotation = laser_raycast.global_rotation
	
	# Create a line for visualization
	var line = Line2D.new()
	laser.add_child(line)
	line.width = 6.0
	line.default_color = player_color
	line.add_point(Vector2.ZERO)
	
	# Use the player's raycast for collision detection
	print("Firing laser - Position:", global_position, " Rotation:", laser_raycast.rotation)
	laser_raycast.force_raycast_update()
	
	# Check for collision
	if laser_raycast.is_colliding():
		var collision_point = laser_raycast.get_collision_point()
		var laser_vector = collision_point - global_position
		var laser_length = laser_vector.length()
		
		var hit_object = laser_raycast.get_collider()
		
		# Check if we hit a player
		if hit_object is CharacterBody2D and hit_object != self:
			# Check if the hit player is reflecting
			if hit_object.is_reflecting:
				print("Hit reflecting player! Redirecting laser!")
				AudioManager.play_sound("reflect_catch")
				# Calculate the exact reflection point
				# Note: For body collisions, we need to find where the ray intersects the reflection area
				
				# First get reflecting player's reflection area
				var reflecting_player = hit_object
				var reflection_area = reflecting_player.reflect_area
				
				# Find the reflection area bounds - we'll use the player's position as an approximation
				var reflection_point = collision_point
				
				# Visually stop the original laser at the reflection point
				line.add_point(Vector2.RIGHT * laser_length)
				
				# Get the reflecting player's aim direction
				var reflect_direction = reflecting_player.look_direction
				
				# Create a new reflected laser starting at the exact reflection point
				var reflected_laser = Node2D.new()
				get_tree().root.add_child(reflected_laser)
				reflected_laser.global_position = reflection_point
				
				# Use the reflecting player's current aim direction
				reflected_laser.rotation = reflecting_player.reflect_area.global_rotation
				
				# Create the reflected laser line with the ORIGINAL shooter's color
				var reflected_line = Line2D.new()
				reflected_laser.add_child(reflected_line)
				reflected_line.width = 6.0
				reflected_line.default_color = player_color  # Keep original laser color
				reflected_line.add_point(Vector2.ZERO)
				
				# Create a raycast for the reflected laser
				var reflected_raycast = RayCast2D.new()
				reflected_laser.add_child(reflected_raycast)
				reflected_raycast.target_position = Vector2.RIGHT * laser_range
				reflected_raycast.collision_mask = 1
				
				# Wait one frame for raycast to initialize
				await get_tree().process_frame
				reflected_raycast.force_raycast_update()
				
				# Check for collision of reflected laser
				if reflected_raycast.is_colliding():
					var reflected_hit_point = reflected_raycast.get_collision_point()
					var reflected_vector = reflected_hit_point - reflected_laser.global_position
					var reflected_length = reflected_vector.length()
					reflected_line.add_point(Vector2.RIGHT * reflected_length)
					
					var reflected_hit_object = reflected_raycast.get_collider()
					if reflected_hit_object is CharacterBody2D and reflected_hit_object != reflecting_player:
						print("Reflected laser hit:", reflected_hit_object.name)
						if reflected_hit_object.has_method("take_damage"):
							reflected_hit_object.take_damage(laser_damage)
							print("Applied reflected damage to:", reflected_hit_object.name)
				else:
					# No collision, draw to max range
					reflected_line.add_point(Vector2.RIGHT * laser_range)
				
				# Visual feedback for successful reflection
				var reflection_flash = create_tween()
				reflection_flash.tween_property(reflecting_player.get_node("Sprite"), "modulate", Color.WHITE, 0.1)
				reflection_flash.tween_property(reflecting_player.get_node("Sprite"), "modulate", reflecting_player.player_color, 0.1)
				
				# Add a visual flash effect at the reflection point
				var flash = ColorRect.new()
				get_tree().root.add_child(flash)
				flash.global_position = reflection_point - Vector2(10, 10)
				flash.size = Vector2(20, 20)
				flash.color = player_color.lightened(0.5)  # Use original laser's color
				
				var flash_tween = create_tween()
				flash_tween.tween_property(flash, "modulate:a", 0.0, 0.2)
				flash_tween.tween_callback(flash.queue_free)
				
				# Fade out the reflected laser
				var reflected_tween = create_tween()
				reflected_tween.tween_property(reflected_line, "modulate:a", 0.0, 0.5)
				reflected_tween.tween_callback(reflected_laser.queue_free)
				
			else:
				# Player wasn't reflecting, normal hit
				line.add_point(Vector2.RIGHT * laser_length)
				hit_object.take_damage(laser_damage)
				print("Applied ", laser_damage, " damage to target")
		
		# Check if we hit a reflection area directly
		elif hit_object is Area2D and "ReflectArea" in hit_object.name:
			var reflection_area = hit_object
			var reflecting_player = reflection_area.get_parent()
			
			if reflecting_player != self and reflecting_player is CharacterBody2D:  # Don't reflect our own laser
				print("Direct hit on reflection area owned by:", reflecting_player.name)
				
				# Check if the reflection area is active
				if not reflection_area.get_node("Hitbox").disabled:
					print("Reflection area is active, reflecting laser")
					
					# Visually stop the original laser at the exact collision point
					line.add_point(Vector2.RIGHT * laser_length)
					
					# Create a new reflected laser starting at the exact reflection point
					var reflected_laser = Node2D.new()
					get_tree().root.add_child(reflected_laser)
					reflected_laser.global_position = collision_point
					
					# Use the reflecting player's current aim direction
					reflected_laser.rotation = reflection_area.global_rotation
					
					# Create the reflected laser line with the ORIGINAL shooter's color
					var reflected_line = Line2D.new()
					reflected_laser.add_child(reflected_line)
					reflected_line.width = 6.0
					reflected_line.default_color = player_color  # Keep original laser color
					reflected_line.add_point(Vector2.ZERO)
					
					# Create a raycast for the reflected laser
					var reflected_raycast = RayCast2D.new()
					reflected_laser.add_child(reflected_raycast)
					reflected_raycast.target_position = Vector2.RIGHT * laser_range
					reflected_raycast.collision_mask = 1
					
					# Wait one frame for raycast to initialize
					await get_tree().process_frame
					reflected_raycast.force_raycast_update()
					
					# Check for collision of reflected laser
					if reflected_raycast.is_colliding():
						var reflected_hit_point = reflected_raycast.get_collision_point()
						var reflected_vector = reflected_hit_point - reflected_laser.global_position
						var reflected_length = reflected_vector.length()
						reflected_line.add_point(Vector2.RIGHT * reflected_length)
						
						var reflected_hit_object = reflected_raycast.get_collider()
						if reflected_hit_object is CharacterBody2D and reflected_hit_object != reflecting_player:
							print("Reflected laser hit:", reflected_hit_object.name)
							AudioManager.play_sound("hit_reflected")
							if reflected_hit_object.has_method("take_damage"):
								reflected_hit_object.take_damage(laser_damage)
								print("Applied reflected damage to:", reflected_hit_object.name)
					else:
						# No collision, draw to max range
						reflected_line.add_point(Vector2.RIGHT * laser_range)
					
					# Visual feedback for successful reflection
					var reflection_flash = create_tween()
					reflection_flash.tween_property(reflecting_player.get_node("Sprite"), "modulate", Color.WHITE, 0.1)
					reflection_flash.tween_property(reflecting_player.get_node("Sprite"), "modulate", reflecting_player.player_color, 0.1)
					
					# Add a visual flash effect at the reflection point
					var flash = ColorRect.new()
					get_tree().root.add_child(flash)
					flash.global_position = collision_point - Vector2(10, 10)
					flash.size = Vector2(20, 20)
					flash.color = player_color.lightened(0.5)  # Use original laser's color
					
					var flash_tween = create_tween()
					flash_tween.tween_property(flash, "modulate:a", 0.0, 0.2)
					flash_tween.tween_callback(flash.queue_free)
					
					# Fade out the reflected laser
					var reflected_tween = create_tween()
					reflected_tween.tween_property(reflected_line, "modulate:a", 0.0, 0.5)
					reflected_tween.tween_callback(reflected_laser.queue_free)
				else:
					# Regular hit on inactive reflection area, just draw the laser
					line.add_point(Vector2.RIGHT * laser_length)
			else:
				# Regular hit on something else, just draw the laser
				line.add_point(Vector2.RIGHT * laser_length)
		else:
			# Regular hit on something else, just draw the laser
			line.add_point(Vector2.RIGHT * laser_length)
	else:
		# No collision, draw to max range
		var end_point = Vector2.RIGHT * laser_range
		line.add_point(end_point)
		print("Laser missed, ending at max range")
	
	# Fade out the original laser
	var fade_tween = create_tween()
	fade_tween.tween_property(line, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(laser.queue_free)

func take_damage(damage: int):
	# Don't take damage if reflecting
	if is_reflecting:
		print("Player ", player_index, " is reflecting and blocked damage!")
		return
		
	# Visual feedback
	var flash_tween = create_tween()
	flash_tween.tween_property($Sprite, "modulate", Color.WHITE, 0.05)
	flash_tween.tween_property($Sprite, "modulate", player_color, 0.05)
	
	# Use the enhanced layered sound system
	AudioManager.play_hit_impact(global_position)
	
	# Add hit freeze frames for local player effect
	hit_freeze_frames = 5  # Adjust number as needed
	
	# Add more visual juice
	if JuiceManager:
		JuiceManager.player_hit_effect(global_position, player_color)
		
	# Player was hit - emit signal immediately
	print("Player ", player_index, " was hit!")
	emit_signal("player_hit", player_index)
	
func _on_fire_cooldown_timeout():
	can_fire = true
	print("Player ", player_index, " laser cooldown complete - Can fire again")

func _on_dash_cooldown_timeout():
	can_dash = true
	print("Player ", player_index, " dash cooldown complete - Can dash again")

func _on_dash_dur_timeout() -> void:
	# Only end dash if we haven't reached target yet
	if is_dashing and global_position.distance_to(dash_target) > 5:
		is_dashing = false
		velocity = Vector2.ZERO
		print("Player ", player_index, " dash duration ended")

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
