extends Node
class_name settings_manager

## Centralized place for settings

const user_config_path = "user://settings.cfg"
const default_config_path = "res://default_config.cfg"

signal graphics_settings_changed

var configuration := ConfigFile.new()

# Limit config save frequency
var timer : Timer

# Limit dleayed setting application
var apply_timer :Timer

func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect( _save_to_file )
	
	apply_timer = Timer.new()
	add_child(apply_timer)
	apply_timer.one_shot = true
	apply_timer.timeout.connect( apply_physics_fps )
	
	get_tree().get_root().size_changed.connect(_on_window_resized)
	
	load_default()
	load_from_file(user_config_path)
	# Can't know fps immediately. Must wait.
	delayed_physics_fps()
	return


func load_default() -> void:
	var err := configuration.load( default_config_path )
	if err != OK:
		push_error("Failed to load default config")
		return
	# TODO define system specific defaults here
	return

func load_from_file( path : String )->void:
	var user_conf := ConfigFile.new()
	var err := user_conf.load( path )
	if err != OK:
		# Config probably does not exist. Which is fine
		return
	apply_config( user_conf )


func apply_config( new_conf : ConfigFile )->void:
	for section in new_conf.get_sections():
		for key in new_conf.get_section_keys( section ):
			# TODO validate things to avoid invalid configuration
			configuration.set_value( section, key, new_conf.get_value(section, key) )
	
	print( "Applying:")
	utils.print_config( configuration )
	print( "" )
	DisplayServer.window_set_mode( get_window_mode() )
	if DisplayServer.window_get_mode() in [ DisplayServer.WindowMode.WINDOW_MODE_WINDOWED ]:
		get_window().size = get_window_size()
	apply_physics_fps()
	load_keybinds()
	graphics_settings_changed.emit()
	return

func delayed_physics_fps()->void:
	apply_timer.start( 2 )

func apply_physics_fps()->void:
	Engine.physics_ticks_per_second = get_physics_fps()

# Save after interval of no more changes
func delayed_save()->void:
	timer.start( 0.1 )

func _save_to_file()->void:
	configuration.save( user_config_path )
	print( "Saved settings" )


func _on_window_resized()->void:
	if DisplayServer.window_get_mode() == DisplayServer.WindowMode.WINDOW_MODE_MINIMIZED:
		# Ignore minimized
		return
	configuration.set_value( "video", "window_mode", DisplayServer.window_get_mode() )
	if DisplayServer.window_get_mode() == DisplayServer.WindowMode.WINDOW_MODE_WINDOWED:
		configuration.set_value( "video", "window_size", get_viewport().size )
	delayed_save()
	delayed_physics_fps()

#region Getters for settings

func get_msaa()->Viewport.MSAA:
	var value : Viewport.MSAA = configuration.get_value( "video", "msaa")
	if value not in [0, 1, 2, 3]:
		printerr("Invalid msaa ", value)
		value = Viewport.MSAA_4X
		configuration.set_value( "video", "msaa", value )
	return value

func get_texture_filtering()->Viewport.DefaultCanvasItemTextureFilter:
	var value : Viewport.DefaultCanvasItemTextureFilter = configuration.get_value( "video", "texture_filtering")
	if value not in [0, 1, 2, 3]:
		printerr("Invalid texture_filtering ", value )
		value = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
		configuration.set_value( "video", "texture_filtering", value )
	return value

func get_internal_resolution()->Vector2i:
	return configuration.get_value( "video", "internal_resolution")

func get_resolution_flex()->Vector2:
	var value : Vector2 = configuration.get_value( "video", "resoluion_flex")
	return value

func get_fractional_scaling()->bool:
	return configuration.get_value( "video", "fractional_scaling")

func get_window_mode()->DisplayServer.WindowMode:
	return configuration.get_value( "video", "window_mode")

func get_window_size()->Vector2i:
	return configuration.get_value( "video", "window_size")

func get_physics_fps()->int:
	var value : int = configuration.get_value( "video", "physics_fps")
	if value < 1:
		# automatic
		var common_fps : Array[int] = [30, 60, 75, 120, 144]
		var current_fps : float = Engine.get_frames_per_second()
		var target : int = max( int( current_fps ), 60 )
		
		for fps in common_fps:
			if abs(current_fps - fps) < 3:
				target = fps
				break
		if target > 119:
			target = target / 2
		print( "Targeting %d physics fps" % [target])
		return target
	
	return value



#endregion

func load_keybinds()->void:
	if not configuration.has_section("keys"):
		return
	for a in configuration.get_section_keys("keys"):
		if !InputMap.has_action( a ):
			push_error( "INVALID ACTION: ", str( a ) )
		var key : InputEvent = configuration.get_value("keys", a) 
		InputMap.action_erase_events(a)
		InputMap.action_add_event(a, key)
		
	pass

func set_key( action : StringName, key : InputEvent )->void:
	configuration.set_value( "keys", str(action), key )
