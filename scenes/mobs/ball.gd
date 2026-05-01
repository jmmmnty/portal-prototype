extends StaticBody2D
class_name Sphere

const MAX_SLIDES : int = 4

@export var texture : Texture2D
@export var tint_color : Color = Color.WHITE

@export var friction : float = 0
@export var bounciness : float = 1
var diameter : int
@export var mass : float = 1

var visuals : Polygon2D
var sprite : Sprite2D

var collision_shape : CollisionShape2D
var clipped_collision : CollisionPolygon2D

var portal_proximity : Area2D
var proximity_shape : CollisionShape2D

# These two should not be changed after being set.
var approx_visuals : PackedVector2Array
var approx_collision : PackedVector2Array

## Nodes that is shown on the other side of portal
## Are siblings of this node
## Has sprite and collision
var remote_copy : RemoteCopy
var remote_visual : Polygon2D
var remote_sprite : Sprite2D
var remote_collider : CollisionPolygon2D

var angular_velocity : Vector3 = Vector3.ZERO  # rad/s
var current_rotation: Quaternion = Quaternion.IDENTITY

var near_portal : portal_plane
var portal_side : int

# In local coordinates. Is transformed by position
var view_poly : PackedVector2Array
# In global coordinates
var portal_shadow : PackedVector2Array

var audio : AudioStreamPlayer2D

func _ready() -> void:
	create_nodes()
	configure_nodes()
	validate_nodes()
	# Random starting rotation
	var random :Vector2 = Vector2( randf(), randf() ) * 100
	apply_spinning( random, 1 )


func _physics_process(delta: float) -> void:
	move( Vector2.ZERO, false, delta )
	pass



func create_nodes()->void:
	visuals = Polygon2D.new()
	add_child(visuals)
	
	sprite = Sprite2D.new()
	visuals.add_child(sprite)
	
	clipped_collision = CollisionPolygon2D.new()
	add_child(clipped_collision)
	
	collision_shape = CollisionShape2D.new()
	add_child(collision_shape)
	
	portal_proximity = Area2D.new()
	add_child(portal_proximity)
	
	audio = AudioStreamPlayer2D.new()
	audio.stream = load( "res://audio/random_bounce.tres" )
	audio.max_distance = 1000
	audio.attenuation = 1.2
	add_child( audio )
	
	proximity_shape = CollisionShape2D.new()
	portal_proximity.add_child(proximity_shape)
	
	# Remote copy
	remote_copy = RemoteCopy.new()
	remote_copy.original = self
	
	remote_visual = Polygon2D.new()
	remote_copy.add_child( remote_visual )
	
	remote_sprite = Sprite2D.new()
	remote_visual.add_child( remote_sprite )
	
	remote_collider = CollisionPolygon2D.new()
	remote_copy.add_child( remote_collider )
	
	add_sibling.call_deferred(remote_copy)



func configure_nodes()->void:
	assert( texture.get_size().x == texture.get_size().y, "Ball texture should be square" )
	diameter = int( texture.get_size().x )
	var radius : int = int( diameter / 2 )
	approx_visuals = utils.create_square_polygon( diameter )
	view_poly = utils.create_square_polygon( diameter )
	
	visuals.polygon = approx_visuals
	visuals.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	
	sprite.texture = texture
	sprite.material = load( "res://materials/ball.tres" ).duplicate()
	sprite.material.set_shader_parameter("tint_color", tint_color)
	
	var coll_shape : CircleShape2D = CircleShape2D.new()
	coll_shape.radius = int( radius )
	collision_shape.shape = coll_shape
	
	approx_collision = utils.circle_polygon( 16, radius )
	clipped_collision.polygon = approx_collision
	clipped_collision.disabled = true
	
	var proximity_circle : CircleShape2D = CircleShape2D.new()
	proximity_circle.radius = diameter * 1.1 / 2 + 10
	proximity_shape.shape = proximity_circle
	
	portal_proximity.collision_layer = 0
	portal_proximity.collision_mask = 16
	portal_proximity.monitorable = false
	portal_proximity.connect( "area_entered", portal_entered )
	portal_proximity.connect( "area_exited", portal_exited )
	
	remote_copy.collision_layer = collision_layer
	remote_copy.collision_mask = collision_mask
	
	remote_visual.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	remote_visual.hide()
	
	remote_sprite.texture = texture
	remote_sprite.material = sprite.material


func validate_nodes()->void:
	pass



#region movement code

func move( _direction : Vector2, _stop : bool, delta : float ) -> void:
	
	var velocity : Vector2 = angular_to_linear_2d( angular_velocity )
	
	# Distance traveled during this frame.
	var dist : float
	
	if near_portal:
		# Clip collision before moving
		# So we can ignore walls behind the portal
		var offset : Vector2 = delta * velocity
		clip_collision( portal_shadow, near_portal.global_position, offset )
		clip_copy_collision()
		
		# IDK if this needs to be recalculated here
		var old_portal_side : int = near_portal.portal_side(global_position)
		
		var old_pos : Vector2 = position
		dist = move_and_slide_p( delta, velocity )
		apply_spinning( position-old_pos, delta )
		
		var new_portal_side : int = near_portal.portal_side(global_position)
		
		# You are not allowed to stand right on top of portal.
		if new_portal_side == 0:
			position += velocity.normalized()
			new_portal_side = near_portal.portal_side(global_position)
			if new_portal_side == 0:
				push_warning( "STILL STANDING ON TOP OF PORTAL" )


		if new_portal_side != old_portal_side and near_portal.point_is_in_portal( global_position ):
			# Teleported
			teleport( near_portal )
			portal_shadow = near_portal.occluded_area( position, Transform2D( 0, global_position ) * view_poly  )
			clip_collision( portal_shadow, near_portal.global_position, offset )
			clip_copy_collision()
			portal_side = new_portal_side
		else:
			portal_shadow = near_portal.occluded_area( position, Transform2D( 0, global_position ) * view_poly  )
			clip_collision( portal_shadow, near_portal.global_position, Vector2(0,0) )
			clip_visuals( near_portal.global_position, portal_shadow )

		set_copy_visual()
		
	else:
		var old_pos : Vector2 = position
		dist = move_and_slide_p( delta, velocity  )
		apply_spinning( position - old_pos, delta )
	apply_friction( dist, delta )


## Moves and handles collision
## Returns total distance moved. Including zigzagging.
func move_and_slide_p( delta : float, velocity : Vector2 ) -> float:
	var motion_vector : Vector2 = velocity * delta
	var total_travel : float = 0
	
	if near_portal:
		remote_copy.transform = near_portal.transform_to_other_side( transform )
		
		for i in range(MAX_SLIDES):
			var motion_vector_copy : Vector2 = near_portal.rotation_transform * motion_vector
			var col : KinematicCollision2D = move_and_collide(motion_vector)
			var col_copy : KinematicCollision2D = remote_copy.move_and_collide(motion_vector_copy)
			
			if not col and not col_copy:
				# No collisions. All done
				total_travel += motion_vector.length()
				break
			
			var collision : KinematicCollision2D
			var portal : portal_plane = null
			if col and utils.is_shorter_collision( col, col_copy ):
				# Real collided first
				collision = col
				remote_copy.transform = near_portal.transform_to_other_side( transform )
				total_travel += col.get_travel().length()
			else:
				# Remote copy collided first
				collision = col_copy
				portal = near_portal
				position = near_portal.other_side.point_to_other_side( remote_copy.position )
			
			motion_vector = handle_collision( motion_vector, collision, portal )
			total_travel += collision.get_travel().length()
			
	else:
		for i in range(MAX_SLIDES):
			var col : KinematicCollision2D = move_and_collide(motion_vector)
			if col:
				motion_vector = handle_collision( motion_vector, col, null )
				total_travel += col.get_travel().length()
			else:
				total_travel += motion_vector.length()
				break
	return total_travel

## Returns motion vector after collision
func handle_collision( motion : Vector2, collision : KinematicCollision2D, portal : portal_plane )-> Vector2:
	var motion_transform : Transform2D = Transform2D.IDENTITY
	var collision_normal : Vector2
	
	if portal:
		# Collision happens on other side of portal. Vectors need to be appropriately transformed
		collision_normal = portal.other_side.rotation_transform * collision.get_normal()
	else:
		collision_normal = collision.get_normal()
	
	var collider_a : Sphere = self
	var collider_b : Sphere
	var behind_portal : bool = false
	if collision.get_collider() is RemoteCopy:
		# Collider B is behind portal
		behind_portal = true
		collider_b = collision.get_collider().original
	elif collision.get_collider() is Sphere or collision.get_collider() is Mob:
		collider_b = collision.get_collider()
	else:
		# Collision with wall or something
		var reflect : Vector2 = motion.bounce( collision_normal )
		var angle : float = motion.angle_to(reflect)
		motion_transform = motion_transform.rotated( angle ) * bounciness
		motion = motion_transform * motion
		angular_velocity = utils.rotate_angular_velocity( angular_velocity, motion_transform )
		var vel_normal : Vector2 = angular_to_linear_2d( angular_velocity ).project( collision_normal )
		on_collision_audio( collision.get_position(), vel_normal.length_squared() )
		return motion

	
	var ang_velocity_a : Vector3 = collider_a.angular_velocity
	var ang_velocity_b : Vector3 = collider_b.angular_velocity
	
	if portal:
		# Collider A remote copy collides on other side of portal
		ang_velocity_b = utils.rotate_angular_velocity( ang_velocity_b, portal.other_side.rotation_transform )
	elif behind_portal:
		# Collider B remote copy is collided on this side of portal
		ang_velocity_b = utils.rotate_angular_velocity( ang_velocity_b, collider_b.near_portal.other_side.rotation_transform )
	
	var coll_bounce : float = ( collider_a.bounciness + collider_b.bounciness ) / 2
	
	var vel_a : Vector2 = collider_a.angular_to_linear_2d( ang_velocity_a )
	var vel_b : Vector2 = collider_b.angular_to_linear_2d( ang_velocity_b )
	
	var vel_norm_a : Vector2 = vel_a.project( collision_normal )
	var vel_norm_b : Vector2 = vel_b.project( collision_normal )
	
	## TEST
	# Using 3d simplifies math so all 2d things are here 3d.
	
	var normal : Vector3 = Vector3( collision_normal.x, collision_normal.y, 0 )
	
	var vel_a3 : Vector3 = collider_a.angular_to_linear( ang_velocity_a )
	var vel_b3 : Vector3 = collider_b.angular_to_linear( ang_velocity_b )
	
	# No up
	vel_a3.z = 0
	vel_b3.z = 0
	
	var vel_rel : Vector3 = vel_b3 - vel_a3
	
	if vel_b3.project(normal).length_squared() > 0 and vel_rel.dot(normal) < 0 :
		# False collision. Moving away from each other
		return motion
	
	
	# Proper angular velocity with correct direction
	var ang_a : Vector3 = ang_velocity_a
	var ang_b : Vector3 = ang_velocity_b
	
	var moment_a : float = collider_a.mass * collider_a.diameter * collider_a.diameter / 10
	var moment_b : float = collider_b.mass * collider_b.diameter * collider_b.diameter / 10
	
	var coll_pos : Vector3 = Vector3( collision.get_position().x, collision.get_position().y, 0)
	
	var coll_a_pos : Vector3 = Vector3( collider_a.global_position.x, collider_a.global_position.y, 0 )
	var coll_b_pos : Vector3 = Vector3( collider_b.global_position.x, collider_b.global_position.y, 0 )
	
	if behind_portal or portal:
		var pos2 : Vector2 = collider_b.near_portal.point_to_other_side( collider_b.global_position )
		coll_b_pos = Vector3( pos2.x, pos2.y, 0 )
	if portal:
		var pos2 : Vector2 = portal.other_side.point_to_other_side( collision.get_position() )
		coll_pos = Vector3( pos2.x, pos2.y, 0 )
	
	
	var rel_a : Vector3 = coll_a_pos - coll_pos
	var rel_b : Vector3 = coll_b_pos - coll_pos
	
	# Tangential velocities of the two
	var v_a : Vector3 = vel_a3 + ang_a.cross( rel_a )
	var v_b : Vector3 = vel_b3 + ang_b.cross( rel_b )
	
	var dv : Vector3 = v_b - v_a
	
	var constraint_mass : float = 1/ collider_a.mass + 1/ collider_b.mass
	var tmp : Vector3 = ( 1/moment_a * rel_a.cross( normal ) ).cross( rel_a )
	tmp += ( 1/moment_b * rel_b.cross( normal ) ).cross( rel_b )
	constraint_mass += normal.dot( tmp )
	
	if constraint_mass > 0:
		var jn : float = -dv.dot( normal ) * ( 1 + coll_bounce)
		jn = jn / constraint_mass
		
		vel_a3 -= normal * ( jn / collider_a.mass )
		vel_b3 += normal * ( jn / collider_b.mass )
	
	
	collider_a.angular_velocity = collider_a.linear_to_angular( vel_a3, collider_a.angular_velocity.z )
	collider_b.angular_velocity = collider_b.linear_to_angular( vel_b3, collider_b.angular_velocity.z )
	
	if portal:
		collider_b.angular_velocity = utils.rotate_angular_velocity( collider_b.angular_velocity , portal.other_side.rotation_transform )
	elif behind_portal:
		collider_b.angular_velocity = utils.rotate_angular_velocity( collider_b.angular_velocity, collider_b.near_portal.other_side.rotation_transform )
		
	
	#var motion_2 : Vector2 = collision.get_remainder().length() * vel_tang_a.normalized()
	var motion_2 : Vector2 = Vector2( vel_a3.x, vel_a3.y ).normalized() * collision.get_remainder().length()
	on_collision_audio( collision.get_position(), max( vel_norm_a.length_squared(), vel_norm_b.length_squared() ) )
	return motion_2

func on_collision_audio( _pos : Vector2, intensity : float )->void:
	if intensity < 1000:
		return
	audio.play()

## Modifies ball speed based on friction
func apply_friction( distance_moved : float , delta : float ) -> void:
	# Linear friction
	if distance_moved > 0:
		var loss : float = distance_moved * friction
		var ke1 : float = get_translation_kinetic_energy() + get_rotation_kinetic_energy()
		var ke2 : float = ke1 - loss
		if ke2 < 0.1:
			angular_velocity = Vector3( 0, 0, angular_velocity.z)
		else:
			var spin : float = angular_velocity.z
			angular_velocity = angular_velocity * sqrt( ke2 / ke1 )
			angular_velocity.z = spin
	
	# Rotation friction
	if abs(angular_velocity.z) > 0:
		var mult : float = 1
		if distance_moved < 1:
			# Approximate sliding vs rolling
			mult = 10
		var rot_loss : float = abs(angular_velocity.z) * mult * friction * delta * 15 #TODO multiply with some nice constant
		var re : float = get_spin_kinetic_energy() - rot_loss
		if re < 0.0001:
			angular_velocity.z = 0
		else:
			angular_velocity.z = sqrt( 8 * re / 5 / mass ) / diameter * sign( angular_velocity.z)
	
	


## Total KE. Both translation and rotation. Includes spin
func get_kinetic_energy()->float:
	# Ke = K_lin + K_rot
	# K_lin = mv² / 2
	# |v|² = |w_xy|² * d² / 4
	# k_rot = Iw² / 2
	# I = md² / 10
	var v_lin : Vector2 = angular_to_linear_2d( angular_velocity )
	var ke : float = mass * diameter * diameter * ( v_lin.length_squared() / 8 + angular_velocity.length_squared() / 20 )
	return ke


func angular_to_linear( angular_vel : Vector3 ) -> Vector3:
	var linear : Vector3 = angular_vel.cross( Vector3.BACK ) * diameter / 2
	linear.z = 0
	return linear

func linear_to_angular( linear_vel : Vector3, spin : float ) -> Vector3:
	var angular : Vector3 = linear_vel.cross( Vector3.FORWARD ) / diameter * 2
	angular.z = spin
	return angular

func angular_to_linear_2d( angular_vel : Vector3 ) -> Vector2:
	var linear : Vector3 = angular_to_linear( angular_vel )
	var lin_2d : Vector2 = Vector2( linear.x, linear.y )
	return lin_2d

## KE from linear motion
func get_translation_kinetic_energy()->float:
	var v_lin : Vector2 = angular_to_linear_2d( angular_velocity )
	return mass * v_lin.length_squared() / 4

## KE from rotation. Ignores spin
func get_rotation_kinetic_energy()->float:
	var w : Vector2 = Vector2( angular_velocity.x, angular_velocity.y )
	return mass * diameter * w.length_squared() / 20

## KE from spinning
func get_spin_kinetic_energy()->float:
	return mass * diameter * diameter * 5 / 8 * angular_velocity.z * angular_velocity.z


func teleport( portal : portal_plane )->void:
	angular_velocity = utils.rotate_angular_velocity( angular_velocity, portal.rotation_transform )
	var zQuaternion : Quaternion = Quaternion(Vector3(0, 0, 1), portal.other_side.rotation_transform.get_rotation())
	current_rotation = current_rotation * zQuaternion
	sprite.material.set_shader_parameter("quaternion", current_rotation)
	remote_sprite.material.set_shader_parameter("quaternion", current_rotation)
	
	portal.teleport_object(self)
	near_portal = portal.other_side
	remote_copy.transform = portal.transform_to_other_side( transform )
	pass


func apply_spinning( distance : Vector2, delta : float ) -> void:
	var xRotation : float =  ( distance ).y / diameter * PI
	var yRotation : float = -( distance ).x / diameter * PI
	var zRotation : float = angular_velocity.z * delta
	var xQuaternion: Quaternion = Quaternion(Vector3(1, 0, 0), xRotation)
	var yQuaternion: Quaternion = Quaternion(Vector3(0, 1, 0), yRotation)
	var zQuaternion: Quaternion = Quaternion(Vector3(0, 0, 1), zRotation)
	current_rotation = current_rotation * xQuaternion * yQuaternion * zQuaternion
	sprite.material.set_shader_parameter("quaternion", current_rotation)
	remote_sprite.material.set_shader_parameter("quaternion", current_rotation)


func clip_collision( portal_shape : PackedVector2Array, portal_global_pos : Vector2, offset : Vector2 ) -> void:
	# TODO this causes crash sometimes
	var clipped : Array = clip_poly_to_portal( approx_collision, portal_shape, portal_global_pos, offset )
	if clipped.size() > 1:
		# There may be holes in the shape when passing through portal at  its edge.
		# TODO decide which shape to use
		clipped_collision.polygon = clipped[0]
		return
	elif clipped.is_empty():
		# Completely "inside" portal
		clipped_collision.polygon = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
		return
	clipped_collision.polygon = clipped[0]
	return

## Clips copy collision shape to fit clipped player collision shape
func clip_copy_collision() -> void:
	var copy_collision : Array = Geometry2D.exclude_polygons( approx_collision, clipped_collision.polygon )
	if copy_collision.size() > 1:
		push_error( "COPY COLLISION SHAPE HAS HOLES IN IT ")
		return
	elif copy_collision.is_empty():
		remote_collider.disabled = true
		return
	remote_collider.polygon = copy_collision[0]
	remote_collider.disabled = false
	return
	
func set_copy_visual() -> void:
	var copy_visual : Array = Geometry2D.exclude_polygons( approx_visuals, visuals.polygon )
	if copy_visual.size() > 1:
		push_error( "COPY VISUAL SHAPE HAS HOLES IN IT")
		remote_visual.polygon = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
		return
	elif copy_visual.is_empty():
		remote_visual.polygon = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	else:
		remote_visual.polygon = copy_visual[0]
	pass



func clip_visuals( portal_global_pos : Vector2, portal_shape : PackedVector2Array ) -> void:
	# I promixe thre is only one polygon
	var clipped : Array = clip_poly_to_portal( approx_visuals, portal_shape, portal_global_pos )
	if clipped.size() > 1:
		push_error( "VISUAL SHAPE HAS HOLES IN IT")
	if clipped.is_empty():
		visuals.polygon = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
		return
	visuals.polygon = clipped[0]
	return


## Cuts "to_clip" with portal removing area on the other side
## Returns list of polygons
func clip_poly_to_portal( to_clip : PackedVector2Array, portal_shape : PackedVector2Array, portal_global_pos : Vector2, offset : Vector2 = Vector2.ZERO ) -> Array[PackedVector2Array]:
	var r : Vector2 = portal_global_pos.round() - global_position.round()
	var clipper : PackedVector2Array = Transform2D(0, -offset + r) * portal_shape
	var clipped : Array = Geometry2D.clip_polygons( to_clip, clipper )
	return clipped

#endregion


func portal_entered( new_portal : portal_plane) -> void:
	assert( new_portal is portal_plane )
	if near_portal:
		# Already near portal.
		return
	print( "ENTERED ", new_portal.name, " to ", name )
	collision_shape.set_deferred( "disabled" , true )
	clipped_collision.set_deferred( "disabled" , false )
	near_portal = new_portal
	remote_visual.visible = visuals.visible


func portal_exited( area: Area2D ) -> void:
	if area is portal_plane:
		print( "EXITED ", near_portal.name, " to ", name )
		near_portal = null
		collision_shape.set_deferred( "disabled", false )
		clipped_collision.set_deferred( "disabled", true )
		remote_visual.hide()
