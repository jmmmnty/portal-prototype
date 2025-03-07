extends Node2D
class_name map

@export var view_control : Control

var portals : Array[portal_plane]

var player : Mob

## Position at which portal shadows were last sorted
var previous_camera_pos : Vector2 = Vector2.ZERO

func _ready() -> void:
	get_portals()
	pass


func _process( _delta: float) -> void:
	pass

func get_portals() -> void:
	for child in get_children():
		if child is portal_plane:
			portals.append( child )
		#child.get_portals()

## Updates portal shadows to match the camera
func update_portals( camera_pos : Vector2 ) -> void:
	for portal : portal_plane in portals:
		portal.update_position( camera_pos )
	# Sort portal shadows in scene tree every now and then th make them overlap properly
	if previous_camera_pos.distance_squared_to( camera_pos ) > 100:
		previous_camera_pos = camera_pos
		view_control.sort_projections( camera_pos )
		pass
	
	pass

func get_player() -> Mob:
	for child in get_children():
		if child is Mob and child.is_player:
			return child
	return
