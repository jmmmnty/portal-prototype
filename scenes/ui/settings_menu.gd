extends Control

const bool_scene = preload( "res://scenes/ui/settings/setting_bool.tscn" )
const int_scene = preload( "res://scenes/ui/settings/setting_int.tscn" )

@export var tab_container : TabContainer

@export var video_settings : Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialize()
	pass # Replace with function body.


func initialize()->void:
	for tab : Node in tab_container.get_children():
		for node : Node in tab.get_children():
			if node is setting_widget:
				node.load_value( SettingsManager.configuration )
	pass


func construct_config()->ConfigFile:
	var config := ConfigFile.new()
	for tab : Node in tab_container.get_children():
		for node : Node in tab.get_children():
			if node is setting_widget:
				#print( "%s/%s" %[node.variable_group, node.variable_name], node.value )
				config.set_value( node.variable_group, node.variable_name, node.value )
	return config



func _on_apply_button_pressed() -> void:
	var config := construct_config()
	SettingsManager.apply_config( config )
	SettingsManager.delayed_save()


func _on_visibility_changed() -> void:
	# Refresh contents
	if visible:
		initialize()
