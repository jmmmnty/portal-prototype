extends SubViewport

# This thing handles vision blocking walls
# These walls are dynamic as they may be cut by portals
var empty_shape : PackedVector2Array = PackedVector2Array( [ Vector2.ZERO, Vector2.ZERO, Vector2.ZERO ] )

func _ready() -> void:
	ResolutionManager.resolution_changed.connect( set_view_size )
	set_view_size()

func add_wall( wall : solid_wall ) -> void:
	var occluder : VisionOccluder = VisionOccluder.new()
	occluder.set_base_shape( wall.shadow_poly ) 
	occluder.name = wall.name
	$vision.add_child( occluder )

func set_view_size() -> void:
	get_node("Node2D/Polygon2D").polygon = ResolutionManager.viewport_polygon
	size = ResolutionManager.internal_resolution

func slice_occluders( portals : Array[portal_plane], player : Mob ) -> void:
	var visible_portals : Array[portal_plane]
	
	for portal in portals:
		if portal.occlusion_polygon != empty_shape:
			visible_portals.append(portal)
	
	var view_rect : Rect2 = player.get_node( "Camera2D" ).get_viewport_rect() * Global.view_rotation
	view_rect.position = player.position - view_rect.size / 2
	
	
	
	for occluder : VisionOccluder in $vision.get_children():
		# occluder.base_shape is the original shape of the occluder
		# sliced_shapes are shapes after portal shadow has been removed. Usually just occluder.base_shape
		# remote_shapes are shapes that are seen through portal. Usually empty
		var sliced_shapes : Array[PackedVector2Array] = [ occluder.base_shape ]
		var remote_shapes : Array[PackedVector2Array] = []
		
		for portal in visible_portals:
			var portal_rect : Rect2 = portal.other_side.subview_camera.get_viewport_rect()
			portal_rect.position = portal.other_side.subview_camera.position
			var translator : Transform2D = portal.transform_to_other_side( portal.transform )
			var shadow : PackedVector2Array = translator * portal.occlusion_polygon
			if occluder.base_rect.intersects( portal_rect ):
				# This wall is visible on other side of the portal
				# Part of it may need to be taken
				for shape in Geometry2D.intersect_polygons(occluder.base_shape, shadow):
					remote_shapes.append(  portal.other_side.polygon_to_other_side(shape) )
		
		if occluder.base_rect.intersects( view_rect ):
			# This wall is visible without portals
			# It may be covered by a portal
			for portal in visible_portals:
				var translator : Transform2D = Transform2D( 0, portal.position )
				var shadow : PackedVector2Array = translator * portal.occlusion_polygon
				var new_shapes : Array[PackedVector2Array]
				for shape : PackedVector2Array in sliced_shapes:
					new_shapes.append_array( Geometry2D.clip_polygons(shape, shadow ) )
				sliced_shapes = new_shapes
		
		# append_array(array: Array)
		sliced_shapes.append_array(remote_shapes)
		occluder.set_shapes( sliced_shapes )
