extends Control

@export var player : Mob
@export var world : Node2D

var overlay : SubViewportContainer
var subviewports : Array[SubViewport]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = $main_view/SubViewport/world/map.get_player()
	overlay = $overlay
	connect_player()
	connect_portals()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func connect_portals() -> void:
	var projection_scene : PackedScene = preload("res://scenes/portal_projection.tscn")
	
	# Connect all portals
	var portals : Array[portal_plane] = $main_view/SubViewport/world/map.portals
	for portal : portal_plane in portals:
		portal.player = player
		var projection : portal_projection = projection_scene.instantiate()
		portal.projection = projection
		$overlay/SubViewport.add_child(projection)
	
	for portal : portal_plane in portals:
		portal.connect_signals()
	for portal : portal_plane in portals:
		portal.update_position( player.position )

func connect_player()->void:
	# TODO Unhardcode this
	var remote_transform : RemoteTransform2D = player.get_node( "RemoteTransform2D" )
	remote_transform.remote_path = $overlay/SubViewport/Camera2D.get_path()
	player.get_node( "Camera2D" ).overlay_camera = $overlay/SubViewport/Camera2D
	pass



func sort_projections( camera_pos : Vector2 ) -> void:
	overlay.sort_projections( camera_pos )
