extends NavigationAgent2D

func _ready() -> void:
	target_position = Vector2( 2144.0, 126)

func _physics_process(delta: float) -> void:
	var next : Vector2 = get_next_path_position()
	#print( next )
	return
