# volume_slider.gd - Updated implementation
extends Control

signal value_changed(new_value)

# Export properties
@export var label: String = "Volume"
@export var max_value: int = 5
@export var current_value: int = 5:
	set(new_value):
		current_value = clamp(new_value, 1, max_value)
		if is_inside_tree():
			update_visuals()
		emit_signal("value_changed", current_value)

# Node references
var boxes = []
var label_node

func _ready():
	# Set a minimum height to prevent overlapping
	custom_minimum_size.y = 40
	
	# Create the slider layout
	var hbox = HBoxContainer.new()
	add_child(hbox)
	
	# Create the label
	label_node = Label.new()
	label_node.text = label
	label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_node.custom_minimum_size.x = 100
	hbox.add_child(label_node)
	
	# Create a container for the boxes
	var box_container = HBoxContainer.new()
	box_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(box_container)
	
	# Create the boxes
	for i in range(max_value):
		var box = TextureRect.new()
		box.texture = preload("res://assets/sprites/player.png")  # Use an existing texture or create a new one
		box.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		box.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.custom_minimum_size = Vector2(24, 24)
		box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Make boxes clickable
		box.mouse_filter = Control.MOUSE_FILTER_STOP
		box.gui_input.connect(_on_box_input.bind(i + 1))
		
		box_container.add_child(box)
		boxes.append(box)
	
	update_visuals()

func update_visuals():
	if boxes.size() == 0:
		return
		
	for i in range(boxes.size()):
		# Box is filled if its index is less than the current value
		if i < current_value:
			boxes[i].modulate = Color(1, 1, 1, 1)  # Fully opaque
		else:
			boxes[i].modulate = Color(1, 1, 1, 0.3)  # Transparent

func _on_box_input(event, box_value):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		set_value(box_value)

func set_value(value):
	current_value = value
