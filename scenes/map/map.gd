extends Node2D
class_name map

@export var view_control : Control
@export var spawn_point : Marker2D
@export var player : Mob

var portals : Array[portal_plane]


## Position at which portal shadows were last sorted
var previous_camera_pos : Vector2 = Vector2.ZERO

func _ready() -> void:
	portals = get_portals()
	Global.player_moved.connect( update_portals )
	player.position = spawn_point.position
	pass


func _process( _delta: float) -> void:
	pass

func get_portals() -> Array[portal_plane]:
	var ret : Array[portal_plane]
	for child in get_children():
		if child is portal_plane:
			ret.append( child )
		else:
			ret.append_array( get_portals_node( child ) )
	return ret

func get_portals_node( node : Node ) -> Array[portal_plane]:
	var ret : Array[portal_plane] = []
	for child in node.get_children():
		if child is portal_plane:
			ret.append(child)
		else:
			ret.append_array( get_portals_node(child) )
	return ret

## Reursively finds all walls in the map
## Returns array of walls
func get_walls( node : Node = self ) -> Array[solid_wall]:
	var ret : Array[solid_wall] = []
	for child in node.get_children():
		if child is solid_wall:
			ret.append( child )
		ret.append_array( get_walls( child ) )
	return ret

## Updates portal shadows to match the camera
func update_portals( camera_pos : Vector2 ) -> void:
	for portal : portal_plane in portals:
		portal.update_position( camera_pos )
	# Sort portal shadows in scene tree every now and then th make them overlap properly
	if previous_camera_pos.distance_squared_to( camera_pos ) > 100:
		previous_camera_pos = camera_pos
		view_control.sort_projections( camera_pos )
		pass
	view_control.update_occlusion()
	
	pass

func get_player() -> Mob:
	for child in get_children():
		if child is Mob and child.is_player:
			return child
	return
