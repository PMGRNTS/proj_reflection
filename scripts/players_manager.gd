extends Node2D


@export var player_scene: PackedScene
@export var spawn_points: Array[Node2D]

var players: Array[CharacterBody2D] = []

func _ready():
	reset_players()
	setup_existing_players()


func setup_existing_players():
	# New code with more explicit setup and debugging
	var player1 = get_node("Player")
	var player2 = get_node("Player2")
	
	print("Found players:", player1 != null, player2 != null)
	
	if player1:
		player1.player_index = 0  # First player
		players.append(player1)
		print("Set up Player 1")
	
	if player2:
		player2.player_index = 1  # Second player
		players.append(player2)
		print("Set up Player 2")

func reset_players():
	for i in players.size():
		if spawn_points.size() > i:
			players[i].global_position = spawn_points[i].global_position
