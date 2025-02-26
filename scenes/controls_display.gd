# controls_display.gd
extends Control

func _ready():
	modulate.a = 0.0

func show_controls():
	# Show control display with fade
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.8, 0.5)
	
	# Auto-hide after a few seconds
	await get_tree().create_timer(4.0).timeout
	
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
