extends SubViewport

# sort nodes every X seconds
var sort_freq : float = 0
var timer : float = 0

func _ready() -> void:
	ResolutionManager.resolution_changed.connect( set_view_size )
	set_view_size()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func add_projection( projection : portal_projection) -> void:
	$projections.add_child( projection )
	pass

## Sort portal shadows from closest to furthest away
## This needs to be done to draw them in right order
func sort_projections( camera_pos : Vector2 ) -> void:
	var children : Array = $projections.get_children()
	var nodes : Array
	for child : portal_projection in children:
		nodes.append( [child, child.position.distance_squared_to( camera_pos ) ] )
	nodes.sort_custom( node_sorter )
	
	var i : int = 0
	for pair : Array in nodes:
		$projections.move_child ( pair[0], i )
		i += 1
	pass

func node_sorter(a : Array, b : Array ) -> bool :
	if a[1] > b[1]:
		return true
	return false

func set_view_size() -> void:
	get_node("Node2D/vision").polygon = ResolutionManager.viewport_polygon
	$Node2D/vision.texture_offset = ResolutionManager.internal_resolution / 2
