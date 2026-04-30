extends Sphere
class_name Mob


const SPEED : float = 150.0



var shader_material: ShaderMaterial

@export var input_component : InputComponent
@export var is_player : bool = false



# Rotation applied to camera
# Also all controls to make them align with rotated camera view
var view_rotation : Transform2D = Transform2D()

func _ready() -> void:
	collision_shape = $CollisionShape2D
	clipped_collision = $ClippedCollision
	portal_proximity = $PortalProximity
	proximity_shape = $PortalProximity/CollisionShape2D
	visuals = $visuals
	sprite = $visuals/Sprite2D
	
	portal_proximity.connect( "area_entered", portal_entered )
	portal_proximity.connect( "area_exited", portal_exited )
	
	# TODO make better diameter
	diameter = int( sprite.texture.get_size().x )
	shader_material = sprite.material as ShaderMaterial
	
	approx_collision = utils.circle_polygon( 16, diameter/2 )
	clipped_collision.polygon = approx_collision
	# TODO make visual approx dynamic
	approx_visuals = visuals.polygon
	
	# Create and configure remote copy
	remote_copy = RemoteCopy.new()
	remote_copy.original = self
	remote_copy.collision_layer = collision_layer
	remote_copy.collision_mask = collision_mask
	
	remote_visual = Polygon2D.new()
	remote_visual.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	remote_visual.hide()
	remote_copy.add_child( remote_visual )
	
	remote_sprite = Sprite2D.new()
	remote_sprite.texture = sprite.texture
	remote_sprite.material = load( "res://materials/ball.tres" )
	remote_visual.add_child( remote_sprite )
	
	remote_collider = CollisionPolygon2D.new()
	remote_copy.add_child( remote_collider )
	
	add_sibling.call_deferred(remote_copy)
	
	var proximity_circle : CircleShape2D = CircleShape2D.new()
	proximity_circle.radius = diameter * 1.1 / 2 + 10
	proximity_shape.shape = proximity_circle
	
	set_components()
	
	# TODO set overlay cam positions
	await get_tree().process_frame
	Global.player_moving( global_position, get_view_poly() )


func _physics_process(_delta: float) -> void:
	# This must be emtpy to replace the base on in ball.gd
	pass

func move( direction : Vector2, stop : bool, delta : float ) -> void:
	# TODO refactor this to be player independend and use move() in ball.gd
	
	var controlled : bool = stop or direction.length() != 0
	
	
	var velocity3 : Vector3 = angular_to_linear( angular_velocity )
	
	if stop:
		angular_velocity = angular_velocity.lerp( Vector3.ZERO, delta*16)
	elif direction.length() != 0:
		var target : Vector3 = Vector3.ZERO
		target.x = (view_rotation * direction).x
		target.y = (view_rotation * direction).y
		target *= SPEED
		velocity3 = velocity3.lerp( target, delta*8)
		angular_velocity = linear_to_angular( velocity3, angular_velocity.z )
	
	var velocity : Vector2 = angular_to_linear_2d( angular_velocity )
	
	# Distance traveled during this frame.
	var dist : float
	
	if near_portal:
		# Clip collision before moving
		# So we can ignore walls behind the portal
		var offset : Vector2 = delta * velocity
		clip_collision( near_portal.occlusion_polygon, near_portal.global_position, offset )
		clip_copy_collision()
		
		# IDK if this needs to be recalculated here
		var old_portal_side : int = near_portal.portal_side(global_position)
		
		var old_pos : Vector2 = position
		dist = move_and_slide_p( delta, velocity )
		apply_spinning( position - old_pos, delta )
		
		var new_portal_side : int = near_portal.portal_side(global_position)
		
		# You are not allowed to stand right on top of portal.
		if new_portal_side == 0:
			position += velocity.normalized()
			new_portal_side = near_portal.portal_side(global_position)
			if new_portal_side == 0:
				push_warning( "STILL STANDING ON TOP OF PORTAL" )
		
		
		if new_portal_side != old_portal_side and near_portal.point_is_in_portal( global_position ):
			# Teleported
			apply_camera_rotation( near_portal.rotation_transform )
			teleport( near_portal )
			clip_collision( near_portal.occlusion_polygon, near_portal.global_position, offset )
			clip_copy_collision()
		
		portal_side = new_portal_side
		
		Global.player_moving( global_position, get_view_poly() )
		clip_collision( near_portal.occlusion_polygon, near_portal.global_position, Vector2(0,0) )
		clip_visuals( near_portal.global_position, near_portal.occlusion_polygon )
		set_copy_visual()
		
	else:
		var old_pos : Vector2 = position
		dist = move_and_slide_p( delta, velocity )
		apply_spinning( position-old_pos, delta )
		Global.player_moving( global_position, get_view_poly() )
	
	if !controlled:
		apply_friction( dist, delta )

func on_collision_audio( _pos : Vector2, intensity : float) -> void:
	if intensity < 1000:
		return
	$AudioStreamPlayer.volume_db = 1
	$AudioStreamPlayer.pitch_scale = 1
	$AudioStreamPlayer.play()
	pass

func apply_camera_rotation( new_rotation : Transform2D )->void:
	# TODO clear this mess
	# TODO Do not save, create, set this here
	view_rotation = new_rotation * view_rotation
	$Camera2D.transform = view_rotation
	Global.set_view_transform( view_rotation )



func set_components() -> void:
	for node : Node in get_children():
		if node is UnitComponent:
			node.main_node = self
	pass



## Polygon area of the world seen by the player. In global coordinates
func get_view_poly()->PackedVector2Array:
	return Transform2D(0, global_position) * view_rotation * ResolutionManager.viewport_polygon
