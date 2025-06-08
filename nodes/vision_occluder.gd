extends LightOccluder2D
class_name VisionOccluder

var base_shape : PackedVector2Array
var base_rect : Rect2

var current_shapes : Array[ PackedVector2Array ]

func _ready() -> void:
	add_shadows( 4 )
	pass


func set_base_shape( new_shape : PackedVector2Array ) -> void:
	base_shape = new_shape
	base_rect = utils.get_polygon_rect( base_shape )
	occluder = OccluderPolygon2D.new()
	occluder.polygon = base_shape
	#occluder.cull_mode = OccluderPolygon2D.CULL_CLOCKWISE



func add_shadows( count : int ) -> void:
	for i in range( count ):
		var new : LightOccluder2D = LightOccluder2D.new()
		new.occluder = OccluderPolygon2D.new()
		add_child( new )

func set_shapes( shapes : Array[PackedVector2Array] ) -> void:
	# TODO rewrite this ugly thing
	if shapes.is_empty():
		hide()
		return
	show()
	occluder.polygon = shapes[-1]
	shapes.resize(shapes.size() - 1)
	
	for child : LightOccluder2D in get_children():
		child.hide()
	
	if shapes.size() > 4:
		push_warning( "SHADOW SPLIT TO TOO MANY PIECES" )
	
	var i : int = 0
	for shape : PackedVector2Array in shapes:
		get_children()[i].occluder.polygon = shape
		get_children()[i].show()
		i += 1
		pass
