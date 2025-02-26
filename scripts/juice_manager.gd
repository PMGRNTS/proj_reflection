# juice_manager.gd
extends Node

# Screen shake parameters
var shake_amount := 0.0
var shake_duration := 0.0
var original_camera_position := Vector2.ZERO
var camera = null

# Flash and particle effects
var hit_particles_scene # = preload("res://scenes/hit_particles.tscn")
var dash_particles_scene # = preload("res://scenes/dash_particles.tscn")

func _ready():
	# We'll try to find the camera, but won't fail if it doesn't exist yet
	find_camera()
	
	# Since you mentioned minimal visuals, let's comment out particle effects
	# until you create the necessary scenes
	# hit_particles_scene = preload("res://scenes/hit_particles.tscn")
	# dash_particles_scene = preload("res://scenes/dash_particles.tscn")

func find_camera():
	# This function can be called later when the camera is ready
	camera = get_viewport().get_camera_2d()
	if camera:
		original_camera_position = camera.position
		print("JuiceManager: Camera found")
	else:
		print("JuiceManager: No camera found, screen shake will be disabled")

func _process(delta):
	if shake_duration > 0 and camera != null:
		shake_duration -= delta
		camera.position = original_camera_position + Vector2(
			randf_range(-1.0, 1.0) * shake_amount,
			randf_range(-1.0, 1.0) * shake_amount
		)
	elif camera != null:
		camera.position = original_camera_position

func screen_shake(amount: float, duration: float):
	# If no camera exists, try to find it again
	if camera == null:
		find_camera()
		
	if camera != null:
		shake_amount = amount
		shake_duration = duration
	else:
		print("JuiceManager: Cannot shake screen - no camera available")

func player_hit_effect(hit_position: Vector2, player_color: Color):
	# Flash effect - this will work without camera
	var flash = ColorRect.new()
	flash.color = player_color
	flash.color.a = 0.3
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input
	flash.anchors_preset = Control.PRESET_FULL_RECT
	get_tree().root.add_child(flash)
	
	# Fade out the flash
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)
	
	# Screen shake - will only work if camera exists
	screen_shake(5.0, 0.2)
	
	# Particles - only if the scene exists
	if hit_particles_scene:
		spawn_particles(hit_position, player_color, hit_particles_scene)

func dash_effect(player_position: Vector2, player_color: Color, direction: Vector2):
	if dash_particles_scene:
		spawn_particles(player_position, player_color, dash_particles_scene, direction)

func spawn_particles(position: Vector2, color: Color, particles_scene, direction := Vector2.ZERO):
	# Safety check
	if particles_scene == null:
		print("JuiceManager: Cannot spawn particles - scene not loaded")
		return
		
	var particles = particles_scene.instantiate()
	particles.position = position
	particles.modulate = color
	
	# Make sure the process_material exists
	if direction != Vector2.ZERO and particles.has_method("get_process_material"):
		var material = particles.get_process_material()
		if material and material.has_property("direction"):
			material.direction = Vector3(direction.x, direction.y, 0)
			
	get_tree().root.add_child(particles)
