extends Camera

var travelling = false
var speed = 1

onready var start_pos = transform.origin
onready var start_rot = transform.basis.get_euler()

onready var tp = $target_pos

func _process(delta):
	if(travelling):
		travel_to_locrot(speed*delta)

func travel_to_locrot(spd):
	if((transform.origin-tp.transform.origin).length() < 1):
		travelling = false
	
	transform = transform.interpolate_with(tp.transform, spd)

func start_travelling(to_pos, to_rot):
	travelling = true
