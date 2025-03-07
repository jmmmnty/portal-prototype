extends Label

var max_count : int = 60
var index : int = 0
var frametimes : Array[float]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	frametimes.resize( max_count )
	frametimes.fill( 0.0 )
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	index = ( index + 1 ) % max_count
	frametimes[ index ] = delta
	var avg_fps : float = max_count / frametimes.reduce(sum,) 
	text = "%.3f" % [avg_fps]
	pass

func sum(accum : float, number : float)->float:
	return accum + number
