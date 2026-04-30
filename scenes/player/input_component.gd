extends UnitComponent
class_name InputComponent


func _physics_process( delta: float) -> void:
	var direction : Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var stop : bool = Input.is_action_pressed( "move_stop" )
	main_node.move( direction, stop, delta )
	
