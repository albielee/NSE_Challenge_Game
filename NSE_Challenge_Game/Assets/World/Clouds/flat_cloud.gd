extends MeshInstance

onready var spawn_x = transform.origin.x
onready var size = get_aabb().size.x*2

var reset_at = -100
	
func _process(delta):
	if(transform.origin.x < reset_at):
		transform.origin.x = 100
	
	transform.origin.x -= delta
