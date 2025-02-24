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
	# Get references to UI scenes
	loading_screen = get_tree().root.get_node("Main/UI/LoadingScreen")
	main_menu = get_tree().root.get_node("Main/UI/MainMenu")
	game_ui = get_tree().root.get_node("Main/UI/GameUI")
	world = get_tree().root.get_node("Main/World")
	hud_border = get_tree().root.get_node("Main/UI/GameUI/HUDBorder")
	players_manager = get_tree().root.get_node("Main/World/Players")
	
	# Set initial HUD state
	hud_border.scale = Vector2(0.4, 0.4)
	hud_border.modulate.a = 0.0
	
	_show_loading_screen()
	
	await get_tree().create_timer(2.0).timeout
	_show_main_menu()

func start_game() -> void:
	print("GameManager - Starting game with input settings:")
	print("  P1 keyboard setting: ", p1_using_keyboard)
	print("  P2 keyboard setting: ", p2_using_keyboard)
	
	# Hide all menus
	loading_screen.hide()
	main_menu.hide()
	game_ui.show()
	
	# Set game state
	world.process_mode = Node.PROCESS_MODE_INHERIT
	current_scene_name = "game"
	player_scores = [0, 0]
	
	#Initialize input preferences
	InputManager.register_player(
		0, 
		InputManager.InputDevice.KEYBOARD if p1_using_keyboard else InputManager.InputDevice.CONTROLLER,
		0 if not p1_using_keyboard else -1
	)
	
	InputManager.register_player(
		1,
		InputManager.InputDevice.KEYBOARD if p2_using_keyboard else InputManager.InputDevice.CONTROLLER,
		0 if not p2_using_keyboard else -1
	)
	
	# Reset players to starting positions
	players_manager.reset_players()
	
	# Create game boundary
	create_circular_wall()
	
	# Animate HUD
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(hud_border, "scale", Vector2(1.0, 1.0), 0.5)
	
	await tween.finished
	emit_signal("game_started")
	

func _show_loading_screen() -> void:
	loading_screen.show()
	main_menu.hide()
	game_ui.hide()
	world.process_mode = Node.PROCESS_MODE_DISABLED
	current_scene_name = "loading"

func _show_main_menu() -> void:
	loading_screen.hide()
	main_menu.show()
	game_ui.show()  # We show this to see the HUD border
	world.process_mode = Node.PROCESS_MODE_DISABLED
	current_scene_name = "menu"
	get_tree().paused = false
	
	# Animate HUD border for menu state
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(hud_border, "scale", Vector2(0.4, 0.4), 0.5)
	tween.parallel().tween_property(hud_border, "modulate:a", 1.0, 0.5)



func toggle_pause() -> void:
	if current_scene_name != "game":
		return
		
	is_game_paused = !is_game_paused
	get_tree().paused = is_game_paused
	emit_signal("game_paused" if is_game_paused else "game_resumed")

func _on_player_hit(player_index: int):
	# Update high score if this player's score is higher
	if player_scores[player_index] > high_score:
		high_score = player_scores[player_index]
	
	emit_signal("game_over")
	
	# Animate HUD border back to menu size before showing menu
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(hud_border, "scale", Vector2(0.4, 0.4), 0.5)
	
	await tween.finished
	await get_tree().create_timer(0.5).timeout
	_show_main_menu()


func create_circular_wall() -> void:
	# Remove old wall if it exists
	if circular_wall:
		circular_wall.queue_free()
	
	circular_wall = StaticBody2D.new()
	world.add_child(circular_wall)
	circular_wall.global_position = Vector2(360, 360)  # Center position
	
	# Create segments around the circle
	var radius = 320  # Match your HUD border radius
	var segments = 360  # More segments = smoother circle, but more processing
	var angle_delta = 2 * PI / segments
	
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
