extends MeshInstance


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var spawn_x = transform.origin.x
onready var size = get_aabb().size.x*2

var reset_at = -100
# Called when the node enters the scene tree for the first time.
func _ready():
	print(size)
	
func _process(delta):
	if(transform.origin.x < reset_at):
		transform.origin.x = 100
	
	transform.origin.x -= delta
