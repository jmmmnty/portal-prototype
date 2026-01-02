extends Control

@export var player : Mob
@export var world : Node2D

var overlay : SubViewportContainer
var subviewports : Array[SubViewport]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	overlay = $overlay
	connect_player()
	connect_portals()
	connect_walls()
	Global.view_rotated.connect( rotate_camera )
	Global.player_moved.connect( position_camera )
	# Hacky force everything to update
	Global.player_moved.emit( player.position )

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func connect_portals() -> void:
	# Connect all portals
	var portals : Array[portal_plane] = $main_view/SubViewport/world/map.portals
	for portal : portal_plane in portals:
		portal.projection = Polygon2D.new()
		overlay.add_projection( portal.projection )
	
	for portal : portal_plane in portals:
		portal.connect_signals()
	for portal : portal_plane in portals:
		portal.update_position( player.position )

func connect_player()->void:
	# TODO Unhardcode this
	player.get_node( "Camera2D" ).overlay_camera = $overlay/SubViewport/Node2D
	pass

func connect_walls() -> void:
	for wall : solid_wall in $main_view/SubViewport/world/map.get_walls():
		$vision.add_wall( wall )
	pass

func sort_projections( camera_pos : Vector2 ) -> void:
	overlay.sort_projections( camera_pos )

func update_occlusion() -> void:
	# $main_view/SubViewport/world/map.portals
	$vision.slice_occluders( $main_view/SubViewport/world/map.portals, player )
	pass

func rotate_camera( view_rotation : Transform2D ) -> void:
	$vision/Node2D.transform = view_rotation
	$overlay/SubViewport/Node2D.transform = view_rotation
	pass

func position_camera( new_pos : Vector2 ) -> void:
	$vision/Node2D.position = new_pos
	$overlay/SubViewport/Node2D.position = new_pos
	pass
