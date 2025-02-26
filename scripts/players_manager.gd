extends Node2D


@export var player_scene: PackedScene
@export var spawn_points: Array[Node2D]

var players: Array[CharacterBody2D] = []

func _ready():
	# We need to assign player indices before calling reset_players
	# Get references to our player nodes
	var player1 = get_node("Player")
	var player2 = get_node("Player2")
	
	# Explicitly set their indices
	if player1:
		player1.player_index = 0
		print("Set Player 1 index to: ", player1.player_index)
		# Connect player hit signal to GameManager
		player1.player_hit.connect(GameManager._on_player_hit)
		
	if player2:
		player2.player_index = 1  # This is the critical change
		print("Set Player 2 index to: ", player2.player_index)
		# Connect player hit signal to GameManager
		player2.player_hit.connect(GameManager._on_player_hit)
	
	# Now we can add them to our players array and reset positions
	players = [player1, player2]
	reset_players()


			
func setup_existing_players():
	var player1 = get_node("Player")
	var player2 = get_node("Player2")
	
	print("Setting up players...")
	
	if player1:
		player1.player_index = 0  # First player
		players.append(player1)
		print("Player 1 index set to: ", player1.player_index)
	
	if player2:
		player2.player_index = 1  # Second player
		players.append(player2)
		print("Player 2 index set to: ", player2.player_index)

func reset_players():
	for i in players.size():
		if spawn_points.size() > i:
			players[i].global_position = spawn_points[i].global_position

func _on_player_hit(player_index: int):
	# This function passes the signal to the GameManager
	if GameManager:
		GameManager._on_player_hit(player_index)
