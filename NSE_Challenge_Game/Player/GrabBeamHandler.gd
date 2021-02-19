extends Spatial


onready var particles_count = get_child_count()
onready var particles = get_children()
onready var grabbed_rock = get_tree().get_root().get_node("/root/World/TEMP")

var old_rot = 0
var scalar = 40

func _physics_process(delta):
	var rock_pos = grabbed_rock.get_global_transform().origin
	var pos = get_global_transform().origin
	var dist_to_rock = pos.distance_to(rock_pos)
	
	var dif = get_global_transform().basis.get_euler().y-old_rot
	old_rot = get_global_transform().basis.get_euler().y

	var ang_to = pos.angle_to(rock_pos) + 2*PI
#	print(ang_to)
	var spacing = (rock_pos - pos)/particles_count
	var sine_input = deg2rad(180.0)/dist_to_rock

	#1 to particles count because we dont want the spacing of the first particle to be on the space e.g. 0
	for i in range(1, particles_count+1):
		particles[i-1].global_transform.origin = pos + Vector3(spacing.x*i + cos(sine_input*i)*dif*scalar*sin(ang_to - (PI/2)), spacing.y*i, spacing.z*i + cos(sine_input*i)*dif*scalar*cos(ang_to))
		
