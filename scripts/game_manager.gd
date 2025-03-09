extends Node

signal game_started
signal game_paused
signal game_resumed
signal game_over

# Add input preference variables
var p1_using_keyboard := true
var p2_using_keyboard := false

# Scene references
var current_scene_name: String = ""
var loading_screen: Control
var main_menu: Control
var game_ui: Control
var world: Node2D
var circular_mask: TextureRect
var hud_border: Sprite2D
var players_manager: Node2D

var circular_wall: StaticBody2D

# Game state
var player_scores: Array[int] = [0, 0]  # Renamed for clarity
var high_score: int = 0  # This will track the highest individual score
var is_game_paused: bool = false

func _ready():
	print("\n=== Game Manager Initialization ===")
	# Get references to UI scenes
	loading_screen = get_tree().root.get_node("Main/UI/LoadingScreen")
	main_menu = get_tree().root.get_node("Main/UI/MainMenu")
	game_ui = get_tree().root.get_node("Main/UI/GameUI")
	world = get_tree().root.get_node("Main/World")
	hud_border = get_tree().root.get_node("Main/UI/GameUI/HUDBorder")
	players_manager = get_tree().root.get_node("Main/World/Players")
	
	print("Scene references loaded:")
	print("  Loading Screen:", loading_screen != null)
	print("  Main Menu:", main_menu != null)
	print("  Game UI:", game_ui != null)
	print("  World:", world != null)
	print("  HUD Border:", hud_border != null)
	print("  Players Manager:", players_manager != null)
	
	# Set initial HUD state
	hud_border.scale = Vector2(0.4, 0.4)
	hud_border.modulate.a = 0.0
	print("Initial HUD state set - Scale:", hud_border.scale, " Alpha:", hud_border.modulate.a)
	
	_show_loading_screen()
	print("Loading screen displayed")
	
	await get_tree().create_timer(2.0).timeout
	_show_main_menu()
	print("=== Game Manager Initialization Complete ===\n")


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel") and current_scene_name == "game":
		return_to_main_menu()



func start_game() -> void:
	print("\n=== Starting New Game ===")
	print("Input Settings:")
	print("  P1 using keyboard:", p1_using_keyboard)
	print("  P2 using keyboard:", p2_using_keyboard)
	
	# Hide all menus
	loading_screen.hide()
	main_menu.hide()
	game_ui.show()
	print("UI visibility updated")
	
	# Set game state
	world.process_mode = Node.PROCESS_MODE_INHERIT
	current_scene_name = "game"
	player_scores = [0, 0]
	print("Game state initialized:")
	print("  Current scene:", current_scene_name)
	print("  Player scores reset:", player_scores)
	
	# Initialize input preferences with our new InputManager system
	print("\nRegistering player input devices:")
	
	# Player 1 setup
	InputManager.register_player(
		0, 
		InputManager.InputDevice.KEYBOARD if p1_using_keyboard else InputManager.InputDevice.CONTROLLER,
		-1 if p1_using_keyboard else 0  # Use first controller if P1 uses controller
	)
	
	# Player 2 setup - Use controller 1 if available, otherwise controller 0 if P1 isn't using it
	var p2_controller_id = -1
	if not p2_using_keyboard:
		var connected_controllers = Input.get_connected_joypads()
		if connected_controllers.size() > 1:
			p2_controller_id = 1  # Use second controller if available
		elif not p1_using_keyboard:
			print("WARNING: Both players configured for controllers but only one detected")
			print("P2 will use keyboard with arrow keys")
			p2_using_keyboard = true
		else:
			p2_controller_id = 0  # Use first controller
	
	InputManager.register_player(
		1,
		InputManager.InputDevice.KEYBOARD if p2_using_keyboard else InputManager.InputDevice.CONTROLLER,
		p2_controller_id
	)
	
	# Reset players to starting positions
	print("Resetting player positions")
	players_manager.reset_players()
	
	# Create game boundary
	print("Creating game boundary")
	create_circular_wall()
	
	# Animate HUD
	print("Starting HUD animation")
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(hud_border, "scale", Vector2(1.0, 1.0), 0.5)
	tween.parallel().tween_property(hud_border, "modulate:a", 1.0, 0.5)
	
	await tween.finished
	print("HUD animation complete")
	emit_signal("game_started")
	print("=== Game Start Complete ===\n")
	
	# Show controls briefly
	var controls_display = get_tree().root.get_node_or_null("Main/UI/GameUI/ControlsDisplay")
	if controls_display:
		controls_display.show_controls()
	
	if has_node("/root/SettingsManager"):
		var settings = SettingsManager.gameplay_settings
		
		# Find players and apply settings
		var player1 = players_manager.get_node("Player")
		var player2 = players_manager.get_node("Player2")
		
		# Apply dash settings
		if player1:
			player1.dash_cooldown_time = settings.dash_cooldown
			player1.reflect_duration = settings.reflect_duration
			player1.fire_rate = settings.fire_cooldown
			
			# Update timers with new values
			player1.dash_cooldown.wait_time = settings.dash_cooldown
			player1.fire_cooldown.wait_time = settings.fire_cooldown
		
		if player2:
			player2.dash_cooldown_time = settings.dash_cooldown
			player2.reflect_duration = settings.reflect_duration
			player2.fire_rate = settings.fire_cooldown
			
			# Update timers with new values
			player2.dash_cooldown.wait_time = settings.dash_cooldown
			player2.fire_cooldown.wait_time = settings.fire_cooldown
			
		print("Applied gameplay settings to players")
		
		
	
func _show_loading_screen() -> void:
	print("\n=== Showing Loading Screen ===")
	loading_screen.show()
	main_menu.hide()
	game_ui.hide()
	world.process_mode = Node.PROCESS_MODE_DISABLED
	current_scene_name = "loading"
	print("Scene state updated:")
	print("  Current scene:", current_scene_name)
	print("  World process mode:", world.process_mode)
	print("=== Loading Screen Ready ===\n")

func _show_main_menu() -> void:
	print("\n=== Showing Main Menu ===")
	loading_screen.hide()
	main_menu.show()
	game_ui.show()  # We show this to see the HUD border
	world.process_mode = Node.PROCESS_MODE_DISABLED
	current_scene_name = "menu"
	get_tree().paused = false
	
	print("Scene state updated:")
	print("  Current scene:", current_scene_name)
	print("  World process mode:", world.process_mode)
	print("  Game paused:", get_tree().paused)
	
	# Animate HUD border for menu state
	print("Starting HUD animation")
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(hud_border, "scale", Vector2(0.4, 0.4), 0.5)
	tween.parallel().tween_property(hud_border, "modulate:a", 1.0, 0.5)
	print("=== Main Menu Ready ===\n")

func toggle_pause() -> void:
	if current_scene_name != "game":
		print("Pause toggle ignored - Not in game scene")
		return
		
	is_game_paused = !is_game_paused
	get_tree().paused = is_game_paused
	print("\n=== Game Pause State Changed ===")
	print("Paused:", is_game_paused)
	emit_signal("game_paused" if is_game_paused else "game_resumed")
	print("=== Pause State Update Complete ===\n")

func _on_player_hit(player_index: int):
	print("\n=== Player Hit Event ===")
	print("Player index:", player_index)
	
	# Increment opponent's score (the player who scored the hit)
	var scorer_index = 1 if player_index == 0 else 0
	player_scores[scorer_index] += 1
	print("Player", scorer_index, "scored! New score:", player_scores[scorer_index])
	
	# Update high score if needed
	if player_scores[scorer_index] > high_score:
		high_score = player_scores[scorer_index]
		print("New high score:", high_score)
	
	# Update score display
	update_score_display()
	
	# Visual feedback for scoring
	var scorer_color = Color(0.294, 0.612, 1.0) if scorer_index == 0 else Color(1.0, 0.294, 0.294)
	var flash = ColorRect.new()
	flash.color = scorer_color
	flash.color.a = 0.3
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.anchors_preset = Control.PRESET_FULL_RECT
	game_ui.add_child(flash)
	
	# Fade out the flash
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)
	
	## Play an additional impact sound that works during pause
	## This takes advantage of the "process while paused" feature
	#var impact_sound = AudioStreamPlayer.new()
	#impact_sound.stream = load("res://assets/sounds/hit_impact_heavy.wav") # Create this sound
	#impact_sound.volume_db = 5.0  # Make it loud
	#impact_sound.pitch_scale = 0.8  # Lower pitch for more impact
	#impact_sound.process_mode = Node.PROCESS_MODE_ALWAYS  # Will play during pause
	#game_ui.add_child(impact_sound)
	#impact_sound.play()
	
	## Clean up sound when finished
	#await impact_sound.finished
	#impact_sound.queue_free()
	#
	# Pause briefly to emphasize the hit
	get_tree().paused = true
	await get_tree().create_timer(1.0, true).timeout
	get_tree().paused = false
	
	# Reset players to starting positions
	print("Resetting players for next point")
	players_manager.reset_players()
	print("=== Round Complete ===\n")
	
func create_circular_wall() -> void:
	print("\n=== Creating Circular Wall ===")
	# Remove old wall if it exists
	if circular_wall:
		print("Removing existing wall")
		circular_wall.queue_free()
	
	circular_wall = StaticBody2D.new()
	world.add_child(circular_wall)
	circular_wall.global_position = Vector2(360, 360)  # Center position
	print("New wall created at position:", circular_wall.global_position)
	
	# Create segments around the circle
	var radius = 320  # Match your HUD border radius
	var segments = 360  # More segments = smoother circle, but more processing
	var angle_delta = 2 * PI / segments
	
	print("Wall parameters:")
	print("  Radius:", radius)
	print("  Segments:", segments)
	print("  Segment angle:", angle_delta)
	
	var segments_created = 0
	for i in range(segments):
		var segment = StaticBody2D.new()
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		
		# Create small rectangular segments
		shape.size = Vector2(20, 2)  # Length and thickness of each segment
		collision.shape = shape
		segment.add_child(collision)
		
		# Position each segment around the circle
		var angle = i * angle_delta
		var segment_position = Vector2(cos(angle) * radius, sin(angle) * radius)
		segment.position = segment_position
		
		# Rotate the segment to face tangent to the circle
		segment.rotation = angle + PI/2
		
		circular_wall.add_child(segment)
		segments_created += 1
	
	print("Wall creation complete:")
	print("  Total segments created:", segments_created)
	print("=== Circular Wall Setup Complete ===\n")

func update_score_display():
	# Update UI elements with current scores
	var p1_score_label = get_tree().root.get_node("Main/UI/GameUI/ScoreDisplay/P1Score")
	var p2_score_label = get_tree().root.get_node("Main/UI/GameUI/ScoreDisplay/P2Score")
	
	if p1_score_label and p2_score_label:
		p1_score_label.text = str(player_scores[0])
		p2_score_label.text = str(player_scores[1])


func return_to_main_menu() -> void:
	print("\n=== Returning to Main Menu ===")
	
	# Reset game state
	is_game_paused = false
	get_tree().paused = false
	
	# Reset scores
	player_scores = [0, 0]
	
	# Remove circular wall if it exists
	if circular_wall:
		circular_wall.queue_free()
	
	# Return to menu
	_show_main_menu()
	print("=== Return to Main Menu Complete ===\n")
