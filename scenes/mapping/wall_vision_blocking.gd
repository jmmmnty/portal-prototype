extends Polygon2D
class_name solid_wall

var shadow_poly : PackedVector2Array 

func _ready() -> void:
	
	# TODO the polygon may be spliced into multiple parts
	shadow_poly = Geometry2D.offset_polygon( polygon, -10)[0]
	shadow_poly = utils.integer_polygon( shadow_poly )
	#var occluder := LightOccluder2D.new()
	#add_child(occluder)
	#occluder.occluder = OccluderPolygon2D.new()
	#occluder.occluder.polygon = shadow_poly
	
	var collision := StaticBody2D.new()
	add_child(collision)
	var coll_shape := CollisionPolygon2D.new()
	collision.add_child(coll_shape)
	coll_shape.polygon = polygon
