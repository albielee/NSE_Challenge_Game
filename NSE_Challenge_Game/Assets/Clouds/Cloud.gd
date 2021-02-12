extends Spatial


var x_limit = -30
var height_dif = 2
var z_dif = 18
var spawn_pos = Vector3(rand_range(x_limit+10, 30), rand_range(-height_dif-1,-2), rand_range(-z_dif/4,z_dif))

var move_speed = rand_range(1,3)

func _ready():
	transform.origin = spawn_pos

func _process(delta):
	transform.origin.x -= move_speed*delta
	if(transform.origin.x < x_limit):
		transform.origin = Vector3(30, rand_range(-height_dif-1,-2), rand_range(-z_dif,z_dif))
		move_speed = rand_range(1,3)
