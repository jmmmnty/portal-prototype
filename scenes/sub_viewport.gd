extends SubViewport

# sort nodes every X seconds
var sort_freq : float = 0
var timer : float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


## Sort portal shadows from closest to furthest away
## This needs to be done to draw them in right order
func sort_projections( camera_pos : Vector2 ) -> void:
	var children : Array = get_children()
	var nodes : Array
	for child : Node2D in children:
		nodes.append( [child, child.position.distance_squared_to( camera_pos ) ] )
	nodes.sort_custom( node_sorter )
	
	var i : int = 0
	for pair : Array in nodes:
		move_child ( pair[0], i )
		i += 1
	pass

func node_sorter(a : Array, b : Array ) -> bool :
	if a[1] > b[1]:
		return true
	return false
