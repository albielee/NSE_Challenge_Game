extends Spatial


var x_limit = -70
var height_dif = 10
var upper_z_dif = -50
var lower_z_dif = 5

var move_speed = rand_range(1,2)
var spawn_height = transform.origin.y


func _process(delta):
	transform.origin.x -= move_speed*delta
	if(transform.origin.x < x_limit):
		transform.origin = Vector3(rand_range(50,70), spawn_height+rand_range(-height_dif-1,-2), rand_range(lower_z_dif,upper_z_dif))
		move_speed = rand_range(1,3)
