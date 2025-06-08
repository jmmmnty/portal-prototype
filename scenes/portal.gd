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

# Transforms from this side to other side
# If portals are at angle this is valid only at the origin of the portal
var teleport_transform : Transform2D

# This is the shadow of the portal in the overlay viewport
var projection : portal_projection



# Nodes internal to portal
## Collider that allows player to detect nearby portals
var plane_collision : CollisionPolygon2D

## SubViewport that sees area around this portal
var subview : portal_viewport2
## Camera for the above SubViewport
var subview_camera : Camera2D

## Visual elements visible in editor
var editor_vis : Node2D
## Plane of the portal seen in editor
var portal_shape : Line2D
## Line to connected portal seen in editor
var portal_connection : Line2D


signal shape_changed( new_polygon : PackedVector2Array )

func _ready() -> void:
	if !Engine.is_editor_hint():
		# Hide editor visuals
		initialize()
		if editor_vis:
			editor_vis.queue_free()
		# Precalculate normal
		normal = Vector2(point_right).orthogonal()
		rotation_transform = calc_rotation_transform()
		teleport_transform = calc_tele_transform()
		set_portal_shape()
		test()
	else:
		# Running in editor
		initialize_editor_vis()
		set_editor_visuals()


func initialize() -> void:
	print( "Initializing portal: " + name )
	
	if point_right.length_squared() != other_side.point_right.length_squared():
		push_warning( "PORTAIL PAIR ARE DIFFERENT SIZE" )
	if not other_side:
		push_warning( "PORTAL WITHOUT OTHER SIDE" )
	if other_side.other_side != self:
		push_warning( "NOT SYMMETRICAL PORTAL CONNECTION" )
	
	collision_layer = 16
	monitoring = false
	
	# CollisionPolygon2D detects when player is near portal
	plane_collision = CollisionPolygon2D.new()
	add_child( plane_collision )
	
	# portal_viewport2 sees area around portal
	subview = portal_viewport2.new()
	subview.snap_2d_transforms_to_pixel = true
	subview.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child( subview )
	
	# camera for the above viewport
	subview_camera = Camera2D.new()
	subview_camera.position = position
	subview_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	subview_camera.ignore_rotation = true
	subview_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	subview.add_child(subview_camera)
	subview.camera = subview_camera
	pass


func initialize_editor_vis() -> void:
	editor_vis = Node2D.new()
	add_child( editor_vis )
	
	portal_shape = Line2D.new()
	portal_shape.default_color = Color( 1, 0.5, 0 )
	portal_shape.width = 1
	editor_vis.add_child(portal_shape)
	
	portal_connection = Line2D.new()
	portal_connection.width = 1
	portal_connection.default_color = Color( 1, 0, 0, 0.2 )
	portal_connection.points = [ Vector2.ZERO, Vector2.ZERO ]
	editor_vis.add_child(portal_connection)
	return


func set_editor_visuals() -> void:
	if not editor_vis:
		push_warning( "TRIED TO UPDATE EDITOR VISUALS WITHOUT EDITOR VISUALS")
		# Can happen when starting godot
		return
	var points : PackedVector2Array
	points.append( point_left )
	points.append( point_right / 2.0 )
	points.append( point_right / 2.0 - Vector2(point_right).orthogonal() / 15 )
	points.append( point_right / 1.9)
	points.append( point_right )
	portal_shape.points = points
	
	portal_connection.points[0] = Vector2.ZERO
	portal_connection.points[1] = other_side.position - position
	print( portal_connection.points )
	return

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

func calc_tele_transform() -> Transform2D:
	var ret : Transform2D = Transform2D()# rotation_transform
	ret.origin =  other_side.position - position
	return ret



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
	plane_collision.polygon = temp
	return


func _set_pair( pair : portal_plane ) -> void:
	if Engine.is_editor_hint():
		set_editor_visuals()
	other_side = pair

func connect_signals()->void:
	# Call this after all the pieces of every portal have been added to the tree
	projection.texture = other_side.subview .get_texture()
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
	shape_changed.emit( occlusion_polygon )
	var offset : Vector2 =  utils.get_polygon_corner( rotation_transform * occlusion_polygon )
	# Camere is always at origin of the portal. But the shadow may not be there
	# So the camera polygon needs to add the endpoints
	var view_polygon : PackedVector2Array = occlusion_polygon.duplicate()
	view_polygon.append_array( endpoints )
	var view_size : Vector2 = utils.get_polygon_size( rotation_transform * view_polygon )
	other_side.subview.set_cam_pos( view_size, offset )
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


func test() -> void:
	pass

## Takes transform on this side of the portal
## Returns same transform on the other side portal
## matrix should be in map coordinates
func transform_to_other_side( matrix : Transform2D ) -> Transform2D:
	return other_side.transform * rotation_transform * matrix * transform.affine_inverse()


func polygon_to_other_side( polygon : PackedVector2Array ) -> PackedVector2Array:
	# Transform polygon to origin
	# rotate polygon
	# transform polygon to other portal
	return polygon * transform * rotation_transform.affine_inverse() * other_side.transform.affine_inverse()


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
	# A bit hacky way to force the other viewport to render immediately now
	# As it may not not be yet in view
	other_side.subview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	subview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	other_side.subview.set_deferred( "render_target_update_mode", SubViewport.UPDATE_ALWAYS  )
	subview.set_deferred( "render_target_update_mode", SubViewport.UPDATE_ALWAYS  )
	print( "TELE DONE")
