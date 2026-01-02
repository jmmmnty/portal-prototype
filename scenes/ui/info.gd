extends Control


func _on_visibility_changed() -> void:
	if visible:
		refresh_info()

func refresh_info()->void:
	var info_text : String = ""
	info_text += "Godot %s %s %s\n" % [ Engine.get_version_info().string, Engine.get_architecture_name() , OS.get_name()]
	info_text += "Internal resolution: "+str( ResolutionManager.internal_resolution ) + "\n"
	info_text += "Game resolution: " + str( get_viewport().size ) + "\n"
	info_text += "Physics fps: %d" % [ Engine.physics_ticks_per_second ]
	$VBoxContainer/RichTextLabel.text = info_text
	pass


func _on_button_pressed() -> void:
	var path := ProjectSettings.globalize_path( "user://" )
	var err := OS.shell_show_in_file_manager( path )
	if err:
		print( "Failed to open user folder ", path)
