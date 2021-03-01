extends Camera

var travelling = false
var speed = 0
var speed_accel = 0.1

onready var tp = get_parent().get_node("target_pos")
onready var pos_vec = (tp.transform.origin-transform.origin)
onready var rot_vec_x = (tp.transform.basis.x-transform.basis.x)
onready var rot_vec_y = (tp.transform.basis.y-transform.basis.y)
onready var rot_vec_z = (tp.transform.basis.z-transform.basis.z)
onready var ambiance = get_parent().get_node("Ambiance")

func _ready():
	ambiance.pitch_scale = 0.1
	

func _process(delta):
	if(travelling):
		travel_to_locrot(speed,delta)

func travel_to_locrot(spd,delta):
	if((transform.origin-tp.transform.origin).length() < 1):
		travelling = false
	if((transform.origin-tp.transform.origin).length() < 20):
		set_zfar(1)

	var d = transform.origin-tp.transform.origin
	if(speed < 0.4):
		speed += speed_accel*delta
	if(ambiance.pitch_scale < 0.5):
		ambiance.pitch_scale += 0.001
	transform.origin += pos_vec*spd*delta
	transform.basis.y += rot_vec_y*spd*delta
	transform.basis.z += rot_vec_z*spd*delta
	transform.basis.x += rot_vec_x*spd*delta
	#transform = transform.interpolate_with(tp.transform, spd)

func start_travelling():
	travelling = true
