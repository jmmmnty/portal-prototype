extends Node

var view_rotation : Transform2D = Transform2D()
signal view_rotated( new_rotation : Transform2D )
signal player_moved( new_position : Vector2)

var old_mode : DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED

var prev_mouse_pos : Vector2 = Vector2.ZERO
var mouse_hide_timer : Timer

func _ready() -> void:
	mouse_hide_timer = Timer.new()
	add_child(mouse_hide_timer)
	mouse_hide_timer.one_shot = true
	mouse_hide_timer.timeout.connect( mouse_hide )
	pass
	
func _process ( _delta : float )-> void:
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("maximize"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode( old_mode )
		else:
			old_mode = DisplayServer.window_get_mode()
			DisplayServer.window_set_mode( DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN )
	
	if not ( prev_mouse_pos - get_viewport().get_mouse_position() ).is_zero_approx():
		prev_mouse_pos = get_viewport().get_mouse_position()
		mouse_hide_timer.start( 2 )
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	

func set_view_transform( new_transform : Transform2D ) -> void:
	view_rotation = new_transform
	view_rotated.emit( new_transform )


func player_moving( player_global_pos : Vector2 ) -> void:
	player_moved.emit( player_global_pos )

func mouse_hide()->void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
