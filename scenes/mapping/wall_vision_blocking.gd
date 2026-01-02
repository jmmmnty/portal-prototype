extends Polygon2D
class_name solid_wall

var shadow_poly : PackedVector2Array

func _ready() -> void:
	# TODO the polygon may be spliced into multiple parts by this
	var temp_polygons : Array[PackedVector2Array] = Geometry2D.offset_polygon( polygon, -10)
	if temp_polygons.size() == 0:
		push_warning( "WALL IS TOO SMALL FOR SHADOW." )
		temp_polygons = [[Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]]
	if temp_polygons.size() > 1:
		push_warning( "WALL IS SPLIT INTO MULTIPLE SHADOW POLYGONS. ONLY FIRST ONE IS USED." )
	shadow_poly = temp_polygons[0]
	shadow_poly = utils.integer_polygon( shadow_poly )
	
	var collision := StaticBody2D.new()
	add_child(collision)
	var coll_shape := CollisionPolygon2D.new()
	collision.add_child(coll_shape)
	coll_shape.polygon =  polygon
