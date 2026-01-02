extends CharacterBody2D
class_name Mob


const SPEED : float = 350.0
const ANGULAR_SPEED : float = 10

@export var input_component : InputComponent
@export var is_player : bool = false

var near_portal : portal_plane
var portal_side : int

# Polygon that approximates collision shape
# Do not change after first set
var approx_collision : PackedVector2Array
# Polygon that covers visual shape of unit
# Do not change after first set
var approx_visual : PackedVector2Array

## Node that is shown on the other side of portal
## Is sibling of the player.
var remote_visual : Polygon2D
var remote_sprite : Sprite2D

var actual_rotation : float = 0

# Rotation applied to camera
# Also all controls to make them align with rotated camera view
var view_rotation : Transform2D = Transform2D()

func _ready() -> void:
	approx_collision = approximate_collision_shape()
	$ClippedCollision.polygon = approx_collision
	# TODO make visual approx dynamic
	approx_visual = $visuals.polygon
	remote_visual = Polygon2D.new()
	remote_sprite = Sprite2D.new()
	remote_visual.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	remote_visual.name = "remote visual"
	remote_visual.hide()
	remote_sprite.texture = $visuals/Sprite2D.texture
	add_sibling.call_deferred(remote_visual)
	remote_visual.add_child( remote_sprite )
	
	set_components()
	set_proximity_shape()
	
	# TODO super hacky way to force rounding errors in our favor
	position += Vector2(0.111, 0.111)
	
	# TODO set overlay cam positions
	await get_tree().process_frame
	Global.player_moving( global_position )
	pass


func move( direction : Vector2, delta : float ) -> void:
	if direction.length() == 0:
		return
	
	velocity = view_rotation * direction * SPEED
	var old_heading : Vector2 = Vector2.from_angle(actual_rotation)
	var angle_diff : float = old_heading.angle_to( velocity )
	if abs(angle_diff) > 0.01:
		actual_rotation += sign(angle_diff) * min( ANGULAR_SPEED * delta, abs(angle_diff) )
	
	if near_portal:
		# Clip collision before moving
		# So we can ignore walls behind the portal
		var offset : Vector2 = delta * velocity
		clip_collision( near_portal, offset )
		clip_copy_collision()
		
		# IDK if this needs to be recalculated here
		var old_portal_side : int = near_portal.portal_side(global_position)
		
		apply_rotation( actual_rotation )
		
		move_and_slide()
		
		var new_portal_side : int = near_portal.portal_side(global_position)
		
		# You are not allowed to stand right on top of portal.
		if new_portal_side == 0:
			position += direction * 0.5
			new_portal_side = near_portal.portal_side(global_position)
			if new_portal_side == 0:
				push_warning( "STILL STANDING ON TOP OF PORTAL" )
		
		
		if new_portal_side != old_portal_side and near_portal.point_is_in_portal( global_position ):
			near_portal.teleport_object(self)
			clip_collision( near_portal, offset )
			clip_copy_collision()
		
		portal_side = new_portal_side
		
		Global.player_moving( global_position )
		clip_collision( near_portal, Vector2(0,0) )
		clip_visuals( near_portal )
		set_copy_position()
		
	else:
		apply_rotation( actual_rotation )
		move_and_slide()
		Global.player_moving( global_position )
	return

func apply_camera_rotation( new_rotation : Transform2D )->void:
	# TODO clear this mess
	# TODO Do not save, create, set this here
	view_rotation = new_rotation * view_rotation
	$Camera2D.transform = view_rotation
	Global.set_view_transform( view_rotation )


func apply_rotation( angle : float ) -> void:
	# Rotating normally would mess up with protal cuts so we can't do that.
	# Instead we need to apply rotation to the relevant nodes by hand
	# TODO Unhardcode node reference
	var rotated_transform : Transform2D = Transform2D(angle, Vector2.ZERO )
	$visuals/Sprite2D.transform = rotated_transform
	return

func add_rotation( angle : float ) -> void:
	actual_rotation = actual_rotation + angle
	var rotated_transform : Transform2D = Transform2D( actual_rotation, Vector2.ZERO )
	$visuals/Sprite2D.transform = rotated_transform

func set_components() -> void:
	for node : Node in get_children():
		if node is UnitComponent:
			node.main_node = self
	pass


func set_proximity_shape() -> void:
	# The area shape must be so that the area hits portal at least one frame before the portal interacts with player
	# radius should be speed * frametime bigger
	var radius : float
	# TODO unhardcode
	radius = $CollisionShape2D.shape.radius
	radius += 10
	$PortalProximity/CollisionShape2D.shape.radius = radius
	return


func set_copy_position() -> void:
	remote_visual.global_transform = near_portal.transform_to_other_side( global_transform )
	var rotated_transform : Transform2D = Transform2D(actual_rotation, Vector2.ZERO )
	remote_sprite.transform = rotated_transform
	var copy_visual : Array = Geometry2D.exclude_polygons( approx_visual, $visuals.polygon )
	if copy_visual.size() > 1:
		push_error( "COPY VISUAL SHAPE HAS HOLES IN IT")
		remote_visual.polygon = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
		return
	elif copy_visual.is_empty():
		remote_visual.polygon = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	else:
		remote_visual.polygon = copy_visual[0]
	pass

## Simpler version of set_copy_position()
## For situations where it does not move. Only rotates
func set_copy_rotation() -> void:
	var rotated_transform : Transform2D = Transform2D(actual_rotation, Vector2.ZERO )
	remote_sprite.transform = rotated_transform
	return

func approximate_collision_shape() -> PackedVector2Array:
	var array : PackedVector2Array
	var sides : int = 9
	# TODO something better than a square
	array.resize(sides)
	
	for i in range( sides ):
		var angle : float = -i * PI * 2 / sides
		array[i] = Vector2.from_angle( angle ) * $CollisionShape2D.shape.radius * 0.9
	
	#var offset : Vector2 = Vector2( -diameter/2, -diameter/2 )
	#array = Transform2D(0, offset) * array
	print( array )
	array = Geometry2D.convex_hull(array)
	
	return array


## Cuts "to_clip" with portal removing area on the other side
## Returns list of polygons
func clip_poly_to_portal( to_clip : PackedVector2Array, portal : portal_plane, offset : Vector2 = Vector2.ZERO ) -> Array[PackedVector2Array]:
	var r : Vector2 = portal.global_position.round() - global_position.round()
	var clipper : PackedVector2Array = Transform2D(0, -offset + r) * portal.occlusion_polygon
	var clipped : Array = Geometry2D.clip_polygons( to_clip, clipper )
	return clipped


## Intersects "to_clip" with portal returning the overlapping area
## Returns list of polygons
func intersect_polygon_to_portal( to_clip : PackedVector2Array, portal : portal_plane, offset : Vector2 = Vector2.ZERO ) -> Array[PackedVector2Array]:
	var r : Vector2 = portal.global_position - global_position
	var clipper : PackedVector2Array = Transform2D(0, -offset + r) * portal.occlusion_polygon
	var clipped : Array = Geometry2D.intersect_polygons(to_clip, clipper )
	return clipped


func clip_collision( portal : portal_plane, offset : Vector2 ) -> void:
	# TODO this causes crash sometimes
	var clipped : Array = clip_poly_to_portal( approx_collision, portal, offset )
	if clipped.size() > 1:
		# There may be holes in the shape when passing through portal at  its edge.
		# TODO decide which shape to use
		$ClippedCollision.polygon = clipped[0]
		return
	elif clipped.is_empty():
		# Completely "inside" portal
		$ClippedCollision.polygon = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
		return
	$ClippedCollision.polygon = clipped[0]
	$ClippedCollision/debug_vis.polygon = clipped[0]
	return


## Clips copy collision shape to fit clipped player collision shape
func clip_copy_collision() -> void:
	$RemoteCollision.transform = transform.inverse() * near_portal.transform_to_other_side( transform )
	var copy_collision : Array = Geometry2D.exclude_polygons( approx_collision, $ClippedCollision.polygon )
	if copy_collision.size() > 1:
		push_error( "COPY COLLISION SHAPE HAS HOLES IN IT ")
		return
	elif copy_collision.is_empty():
		$RemoteCollision.disabled = true
		return
	$RemoteCollision.polygon = copy_collision[0]
	$RemoteCollision/debug_vis.polygon = copy_collision[0]
	$RemoteCollision.disabled = false
	return

func clip_visuals( portal : portal_plane ) -> void:
	# I promixe thre is only one polygon
	var clipped : Array = clip_poly_to_portal( approx_visual, portal )
	if clipped.size() > 1:
		push_error( "VISUAL SHAPE HAS HOLES IN IT")
	if clipped.is_empty():
		$visuals.polygon = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
		return
	$visuals.polygon = clipped[0]
	return


func _on_area_2d_area_entered(area: Area2D) -> void:
	print( "AREA ENTERED: ", area.name, " to ", name )
	if area is portal_plane:
		portal_entered( area )
	pass # Replace with function body.


func _on_area_2d_area_exited(area: Area2D) -> void:
	print( "AREA EXITED: ", area.name, " to ", name )
	if area is portal_plane:
		portal_exited()


func portal_entered( new_portal : portal_plane) -> void:
	if near_portal:
		# Already near portal.
		return
	print( "ENTERED ", new_portal.name, " to ", name )
	$CollisionShape2D.set_deferred( "disabled" , true )
	$ClippedCollision.set_deferred( "disabled" , false )
	near_portal = new_portal
	remote_visual.visible = $visuals.visible


func portal_exited() -> void:
	print( "EXITED ", near_portal.name, " to ", name )
	near_portal = null
	$CollisionShape2D.set_deferred( "disabled", false )
	$ClippedCollision.set_deferred( "disabled", true )
	remote_visual.hide()
