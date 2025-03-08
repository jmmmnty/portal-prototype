@tool
@icon("res://graphics/node_icons/portal_plane.svg")
extends Area2D
class_name portal_plane


@export var other_side : portal_plane :
	set = _set_pair

# Left point is always (0,0)
const point_left : Vector2i = Vector2i.ZERO
@export var point_right : Vector2i = Vector2i.ZERO :
	set = _set_point_right

var endpoints : PackedVector2Array
var occlusion_polygon : PackedVector2Array

var normal : Vector2

# Rotation on teleportation
var rotation_transform : Transform2D

var player : Mob

@onready var viewport : portal_viewport2 = $SubViewport

# This is the shadow of the portal in the overlay viewport
var projection : portal_projection


signal shape_changed( new_polygon : PackedVector2Array )

func _ready() -> void:
	if !Engine.is_editor_hint():
		# Hide editor visuals
		$editor_vis.queue_free()
		# Precalculate normal
		normal = Vector2(point_right).orthogonal()
		rotation_transform = calc_rotation_transform()
		
		set_portal_shape()
	else:
		set_editor_visuals()


func _set_point_right( new_point_2 : Vector2i ) -> void:
	point_right = new_point_2
	if Engine.is_editor_hint():
		set_editor_visuals()
	pass

func calc_rotation_transform() -> Transform2D:
	var ret : Transform2D = Transform2D()
	
	# Rotation matrix
	# a, -b
	# b,  a
	# where
	# a = cos( angle )
	# b = sin( angle )
	# But instead of using trig functions we can calculate like this to avoid
	# rounding errors from angle-radian-trig chain
	# Note that y is down and clockwise is positive
	
	var vec : Vector2 = Vector2( point_right ).normalized()
	var vec2 : Vector2 = Vector2( other_side.point_right ).normalized()
	
	var a : float = ( vec.y * vec2.y + vec.x * vec2.x ) / ( vec.x * vec.x + vec.y * vec.y )
	var b : float = ( vec2.x * vec.y - vec2.y * vec.x ) / ( vec.x * vec.x + vec.y * vec.y )
	
	ret.x = Vector2(a, -b)
	ret.y = Vector2(b, a)
	return ret


func set_editor_visuals() -> void:
	# Setter runs before other nodes have loaded
	var node : Node = get_node_or_null( "editor_vis")
	if node == null:
		return
	$editor_vis.points[6] = Vector2( point_right)
	return


func set_portal_shape() -> void:
	endpoints.resize(2)
	endpoints[0] = Vector2(point_left)
	endpoints[1] =Vector2( point_right)
	
	# For some reaspon 2 polygons is not enough for collision polygon
	var temp : PackedVector2Array
	temp.resize(3)
	temp[0] = endpoints[0]
	temp[1] = endpoints[1]
	temp[2] = endpoints[1]
	$CollisionPolygon2D.polygon = temp
	return


func _set_pair( pair : portal_plane ) -> void:
	other_side = pair

func connect_signals()->void:
	# Call this after all the pieces of every portal have been added to the tree
	projection.texture = other_side.viewport.get_texture()
	projection.position = position
	
	shape_changed.connect( projection.set_shape )
	
	projection.texture_rotation = rotation_transform.get_rotation()
	return

func occluded_area( view_pos : Vector2 ) -> PackedVector2Array:
	var polygon : PackedVector2Array
	polygon.append( endpoints[0] )
	polygon.append( endpoints[1] )
	
	var in_portal : bool = point_is_in_portal( view_pos )
	var dist : float = distance_from_plane( view_pos )
	# Viewer pos in local coordinates and rounded
	var local_view_pos : Vector2 = ( view_pos - position ).round()
	
	
	# Extensions from view pos
	polygon.append( endpoints[1] \
		+ ( endpoints[1] - local_view_pos ).normalized() \
		* ResolutionManager.viewport_resolution.length() *0.5 )
	
	polygon.append( endpoints[0] \
		+ ( endpoints[0] - local_view_pos ).normalized() \
		* ResolutionManager.viewport_resolution.length() *0.5 )
	
	
	# View may be rotated sideways
	var view_area : PackedVector2Array = Transform2D(0, local_view_pos) * Global.view_rotation * ResolutionManager.viewport_polygon
	
	# Extra points in view corners that need to be included
	if dist < 2 and in_portal:
		# This approach works if player is right on top of the portal
		var player_side : int = portal_side( view_pos )
		for point in view_area:
			if portal_side_local( point ) != player_side:
				polygon.append( point )
	else:
		# This approach works if player is some distance away from portal
		for point in view_area:
			if Geometry2D.segment_intersects_segment(endpoints[0],endpoints[1], local_view_pos, point ):
				polygon.append( point )
	
	polygon = Geometry2D.convex_hull(polygon)
	var thing : Array = Geometry2D.intersect_polygons(polygon, view_area)
	
	if thing.size() > 1:
		push_error( "HOLE IN PORTAL SHADOW" )
	elif !thing.is_empty():
		polygon = thing[0]
	else:
		# can't see the portal at all
		polygon = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	
	# We can't have non-integer points in the shape
	for i in range( polygon.size() ):
		polygon[i] = floor( polygon[i] )
	return polygon


func update_position( viewer_position : Vector2 )->void:
	occlusion_polygon = occluded_area( viewer_position )
	$seen_area.polygon = occlusion_polygon
	shape_changed.emit( occlusion_polygon )
	var offset : Vector2 =  utils.get_polygon_corner( rotation_transform * occlusion_polygon )
	var view_size : Vector2 = utils.get_polygon_size( rotation_transform * occlusion_polygon )
	other_side.viewport.set_cam_pos( view_size, offset )
	projection.new_offset( offset )
	return


## Takes pos in map coordinates
func portal_side( pos : Vector2 )->int:
	# -1 is on "front" side
	# +1 is on "back" side
	# 0 is on top of portal
	var r : Vector2 = pos - position
	var tmp : float= r.dot( normal )
	# rounding errors
	if abs(tmp) < 0.1:
		return 0
	return sign( tmp )


## portal_side( pos : Vector2 )
## Except position is in local coordinates
func portal_side_local( local_pos : Vector2 )->int:
	# -1 is on "front" side
	# +1 is on "back" side
	# 0 is on top of portal
	var tmp : float= local_pos.dot( normal )
	# rounding errors
	if abs(tmp) < 0.005:
		return 0
	return sign( tmp )

## Takes point in map coordinates
func distance_from_plane( point : Vector2 ) -> float:
	var closest_point : Vector2 = Geometry2D.get_closest_point_to_segment( point, position, position + Vector2( point_right ) )
	
	var dist : float = closest_point.distance_to( point )
	return dist

## Takes position on this side of the portal
## Returns same position on the other side portal
func point_to_other_side( point : Vector2 ) -> Vector2:
	# There is a rounding error here but I can't find it
	var r : Vector2 = position - point
	r = rotation_transform.basis_xform(r)
	r = other_side.position - r
	return r


## Takes rotation
## Returns rotation passed through the portal
func rotation_to_other_side( rotation_matrix : Transform2D ) -> Transform2D:
	rotation_matrix = rotation_transform * rotation_matrix
	return rotation_matrix

## Takes transform on this side of the portal
## Returns same transform on the other side portal
## matrix should be in map coordinates
func transform_to_other_side( matrix : Transform2D ) -> Transform2D:
	# Translation part
	var r : Vector2 = point_to_other_side( matrix.origin )
	
	# Rotation part
	matrix = rotation_transform * matrix
	matrix.origin = r
	
	return matrix


## Takes transform on this side of the portal
## Returns trans form that when applied to the starting transform moves
## it to the other side
func relative_tranform_to_other_side( matrix : Transform2D ) -> Transform2D:
	# There is a rounding error here but I can't find it
	
	# Translation part
	# Vector from portal corner to transform
	var a1 : Vector2 = matrix.origin - position
	# Vector from other side portal corner to other side transform
	var a2 : Vector2 = rotation_transform.basis_xform(a1)
	# Vector from portal corner to other side portal corner
	var d : Vector2 = other_side.position - position
	# Vector from transform to other side transform
	var t : Vector2 = d + a2 - a1
	
	# Rotation part
	matrix = rotation_transform * matrix
	matrix.origin = t
	
	return matrix


## Returns true if point is in between the portal endpoints.
## "point" is position in map coordinates
## Works only when close to portal relative to portal size
func point_is_in_portal( point : Vector2 ) -> bool:
	# The "point", portal right end and portal left end form a triangle
	# "point" is in between the endpoints if "d" is longest side
	var local : Vector2 = position - point
	var d : float = point_right.length()
	var a : float = ( local ).length()
	var b : float = ( Vector2( point_right ) + local ).length()
	return d > a and d > b

func teleport_object( node : Mob ) -> void:
	print( node.name, " teleported from ", name, " to ", other_side.name)
	#node.transform = transform_to_other_side( node.transform ) # can't do this because too many things rotate based on player
	# TODO uncouple player rotation from everything else
	node.position = point_to_other_side( node.position )
	node.add_rotation( rotation_transform.get_rotation() )
	node.set_copy_position()
	node.apply_camera_rotation( rotation_transform )
	node.near_portal = other_side
	print( "TELE DONE")
