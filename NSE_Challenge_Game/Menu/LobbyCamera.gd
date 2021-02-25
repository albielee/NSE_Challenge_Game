extends Camera

var travelling = false
var speed = 1
var rot_speed = 0.5

onready var start_pos = transform.origin
onready var start_rot = transform.basis.get_euler()

onready var tp = $target_pos

func _process(delta):
	if(travelling):
		travel_to_locrot(speed*delta,  rot_speed*delta)

func travel_to_locrot(spd, r_spd):
	if((transform.origin-tp.transform.origin).length() < 1):
		travelling = false
	
	transform = transform.interpolate_with(tp.transform, 0.001)
	

func start_travelling(to_pos, to_rot):
	travelling = true
