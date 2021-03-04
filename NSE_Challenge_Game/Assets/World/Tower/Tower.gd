extends KinematicBody

var falling = false
var destroy_at_y = -200
var fall_speed = 0
var max_fall_speed = 100
var accel = 5
onready var model_start_pos = $tower.transform.origin

#func _physics_process(delta):
#	if(falling):
#		fall(delta)

func play_anim():
	$AnimationObject.play()

func shake_model():
	var model = $tower
	var random_dir = rand_range(0,2*PI)
	var dist = 0.07
	var new_vector = model_start_pos + Vector3(cos(random_dir)*dist,0,sin(random_dir)*dist)
	model.transform.origin = new_vector

func remove_world_props():
	var areas = $RemoveArea.get_overlapping_areas()
	var bodies = $RemoveArea.get_overlapping_bodies()
	for a in areas:
		if(a.is_in_group("Removable")):
			a.queue_free()
	for b in bodies:
		if(b.is_in_group("Removable")):
			b.queue_free()
	
func begin_fall():
	play_anim()
	remove_world_props()
	falling = true

func fall(delta):
	if(!$AnimationObject.playing):
		if(!$fallSound.playing):
			$fallSound.play()
		#we like a good shake
		shake_model()
		
		if(fall_speed<max_fall_speed):
			fall_speed += accel*delta
		transform.origin.y -= fall_speed*delta
		
		if(transform.origin.y < destroy_at_y):
			queue_free()

