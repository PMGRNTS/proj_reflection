# settings_menu.gd - Updated implementation
extends Control

# Node references (assign in the editor)
@onready var master_volume_slider = $MarginContainer/VBoxContainer/AudioSettings/MasterVolumeSlider
@onready var sfx_volume_slider = $MarginContainer/VBoxContainer/AudioSettings/SFXVolumeSlider
@onready var ui_volume_slider = $MarginContainer/VBoxContainer/AudioSettings/UIVolumeSlider

@onready var dash_cooldown_spinner = $MarginContainer/VBoxContainer/PlayerSettings/DashCooldown
@onready var fire_cooldown_spinner = $MarginContainer/VBoxContainer/PlayerSettings/FireCooldown
@onready var reflect_duration_spinner = $MarginContainer/VBoxContainer/PlayerSettings/ReflectDuration

@onready var fullscreen_toggle = $MarginContainer/VBoxContainer/VideoSettings/FullscreenToggle

@onready var save_button = $MarginContainer/VBoxContainer/ButtonsContainer/SaveButton
@onready var cancel_button = $MarginContainer/VBoxContainer/ButtonsContainer/CancelButton

# Original values when the menu was opened (for cancel functionality)
var original_settings = {
	"master_volume": 5,
	"sfx_volume": 5,
	"ui_volume": 5,
	"dash_cooldown": 0.8,
	"fire_cooldown": 0.75,
	"reflect_duration": 0.7,
	"fullscreen": false
}

func _ready():
	# Fix the layout and centering of the menu
	_setup_menu_layout()
	
	# Connect signals
	save_button.pressed.connect(_on_save_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	ui_volume_slider.value_changed.connect(_on_ui_volume_changed)
	
	dash_cooldown_spinner.value_changed.connect(_on_dash_cooldown_changed)
	fire_cooldown_spinner.value_changed.connect(_on_fire_cooldown_changed)
	reflect_duration_spinner.value_changed.connect(_on_reflect_duration_changed)
	
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	
	# Add headers to each section
	var audio_label = Label.new()
	audio_label.text = "AUDIO SETTINGS"
	audio_label.add_theme_font_size_override("font_size", 24)
	$MarginContainer/VBoxContainer/AudioSettings.add_child(audio_label)
	$MarginContainer/VBoxContainer/AudioSettings.move_child(audio_label, 0)
	
	var gameplay_label = Label.new()
	gameplay_label.text = "GAMEPLAY SETTINGS"
	gameplay_label.add_theme_font_size_override("font_size", 24)
	$MarginContainer/VBoxContainer/PlayerSettings.add_child(gameplay_label)
	$MarginContainer/VBoxContainer/PlayerSettings.move_child(gameplay_label, 0)
	
	# Add labels to each gameplay setting
	add_spinbox_label($MarginContainer/VBoxContainer/PlayerSettings/FireCooldown, "Fire Cooldown")
	add_spinbox_label($MarginContainer/VBoxContainer/PlayerSettings/DashCooldown, "Dash Cooldown")
	add_spinbox_label($MarginContainer/VBoxContainer/PlayerSettings/ReflectDuration, "Reflect Duration")
	
	# Add section spacing
	$MarginContainer/VBoxContainer.add_theme_constant_override("separation", 30)
	
	
	
	
	   # Fix the layout and centering of the menu first
	_setup_menu_layout()
	

	_setup_spinbox_properties()
	
	# Hide menu initially
	hide()

func _setup_menu_layout():
	# Fix centering and sizing
	var margin_container = $MarginContainer
	if margin_container == null:
		push_error("MarginContainer not found in SettingsMenu!")
		return
		
	# Center the container
	margin_container.anchor_right = 1.0
	margin_container.anchor_bottom = 1.0
	margin_container.offset_right = 0
	margin_container.offset_bottom = 0
	
	# Add margins for better appearance
	margin_container.add_theme_constant_override("margin_left", 150)
	margin_container.add_theme_constant_override("margin_right", 150)
	margin_container.add_theme_constant_override("margin_top", 50)
	margin_container.add_theme_constant_override("margin_bottom", 50)
	

	
	# Add spacing between sections
	var main_container = $MarginContainer/VBoxContainer
	if main_container:
		main_container.add_theme_constant_override("separation", 30)
		
		# Center the buttons if they exist
		var button_container = main_container.get_node_or_null("ButtonsContainer")
		if button_container:
			button_container.alignment = BoxContainer.ALIGNMENT_CENTER
			button_container.add_theme_constant_override("separation", 30)





func add_spinbox_label(spinbox: SpinBox, label_text: String):
	var container = HBoxContainer.new()
	var label = Label.new()
	
	# Remove spinbox from its parent
	var parent = spinbox.get_parent()
	var idx = spinbox.get_index()
	parent.remove_child(spinbox)
	
	# Setup label
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = 150
	
	# Add label and spinbox to container
	container.add_child(label)
	container.add_child(spinbox)
	
	# Add container back to parent at same position
	parent.add_child(container)
	parent.move_child(container, idx)

func _setup_spinbox_properties():
	# Set up value ranges and step sizes for spinboxes
	fire_cooldown_spinner.min_value = 0.2
	fire_cooldown_spinner.max_value = 2.0
	fire_cooldown_spinner.step = 0.05
	
	dash_cooldown_spinner.min_value = 0.2
	dash_cooldown_spinner.max_value = 2.0
	dash_cooldown_spinner.step = 0.05
	
	reflect_duration_spinner.min_value = 0.2
	reflect_duration_spinner.max_value = 2.0
	reflect_duration_spinner.step = 0.05

func open_settings():
	# Store original values
	if SettingsManager:
		original_settings.master_volume = SettingsManager.audio_settings.master_volume
		original_settings.sfx_volume = SettingsManager.audio_settings.sfx_volume
		original_settings.ui_volume = SettingsManager.audio_settings.ui_volume
		original_settings.dash_cooldown = SettingsManager.gameplay_settings.dash_cooldown
		original_settings.fire_cooldown = SettingsManager.gameplay_settings.fire_cooldown
		original_settings.reflect_duration = SettingsManager.gameplay_settings.reflect_duration
		original_settings.fullscreen = SettingsManager.video_settings.fullscreen
	
	# Update UI with current settings
	update_ui_from_settings()
	
	# Show menu
	show()

func update_ui_from_settings():
	if SettingsManager:
		master_volume_slider.current_value = SettingsManager.audio_settings.master_volume
		sfx_volume_slider.current_value = SettingsManager.audio_settings.sfx_volume
		ui_volume_slider.current_value = SettingsManager.audio_settings.ui_volume
		
		dash_cooldown_spinner.value = SettingsManager.gameplay_settings.dash_cooldown
		fire_cooldown_spinner.value = SettingsManager.gameplay_settings.fire_cooldown
		reflect_duration_spinner.value = SettingsManager.gameplay_settings.reflect_duration
		
		fullscreen_toggle.button_pressed = SettingsManager.video_settings.fullscreen

# Signal handlers
func _on_master_volume_changed(value):
	if SettingsManager:
		SettingsManager.set_master_volume(value)

func _on_sfx_volume_changed(value):
	if SettingsManager:
		SettingsManager.set_sfx_volume(value)

func _on_ui_volume_changed(value):
	if SettingsManager:
		SettingsManager.set_ui_volume(value)

func _on_dash_cooldown_changed(value):
	if SettingsManager:
		SettingsManager.set_dash_cooldown(value)

func _on_fire_cooldown_changed(value):
	if SettingsManager:
		SettingsManager.set_fire_cooldown(value)

func _on_reflect_duration_changed(value):
	if SettingsManager:
		SettingsManager.set_reflect_duration(value)

func _on_fullscreen_toggled(value):
	if SettingsManager:
		SettingsManager.set_fullscreen(value)

func _on_save_button_pressed():
	if SettingsManager:
		SettingsManager.save_settings()
	hide()

func _on_cancel_button_pressed():
	# Restore original settings
	if SettingsManager:
		SettingsManager.audio_settings.master_volume = original_settings.master_volume
		SettingsManager.audio_settings.sfx_volume = original_settings.sfx_volume
		SettingsManager.audio_settings.ui_volume = original_settings.ui_volume
		SettingsManager.gameplay_settings.dash_cooldown = original_settings.dash_cooldown
		SettingsManager.gameplay_settings.fire_cooldown = original_settings.fire_cooldown
		SettingsManager.gameplay_settings.reflect_duration = original_settings.reflect_duration
		SettingsManager.video_settings.fullscreen = original_settings.fullscreen
		
		# Apply the original settings
		SettingsManager.apply_audio_settings()
		SettingsManager.apply_video_settings()
	
	hide()
