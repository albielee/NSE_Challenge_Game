extends KinematicBody


var falling = false
var destroy_at_y = -200
var fall_speed = 0
var max_fall_speed = 100
var accel = 5
onready var model_start_pos = $tower.transform.origin

func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	#fall(delta)
	pass

func play_anim():
	pass

func shake_model():
	var model = $tower
	var random_dir = rand_range(0,2*PI)
	var dist = 0.1
	var new_vector = model_start_pos + Vector3(cos(random_dir)*dist,0,sin(random_dir)*dist)
	model.transform.origin = new_vector

func fall(delta):
	#we like a good shake
	shake_model()
	
	if(fall_speed<max_fall_speed):
		fall_speed += accel*delta
	transform.origin.y -= fall_speed*delta
	
	if(transform.origin.y < destroy_at_y):
		queue_free()
