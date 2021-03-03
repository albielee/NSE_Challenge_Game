extends Spatial


onready var particles_count = get_child_count()
onready var particles = get_children()
onready var grabbed_rock = get_tree().get_root().get_node("/root/World/TEMP")

var old_rot = 0
var scalar = 10
var active = false
var rot

func start_beam(rock):
	grabbed_rock = rock
	rot = get_global_transform().basis.get_euler().y
	update_position()
	active = true
	visible = true

func stop_beam():
	active = false
	visible = false



func _physics_process(delta):
	if active:
		update_position()
		


func update_position():
	if(grabbed_rock != null):
		var rock_pos = grabbed_rock.get_global_transform().origin
		var pos = get_global_transform().origin
		var dist_to_rock = sqrt(pow((rock_pos.x-pos.x),2)+pow((rock_pos.z-pos.z),2))

		var dif = -(rot-get_global_transform().basis.get_euler().y)
		if dif>PI/2:
			dif = PI/2
		elif dif<-PI/2:
			dif = -PI/2
		var angle = atan2(rock_pos.z-pos.z,rock_pos.x-pos.x)
		var newy = (rock_pos-pos)/particles_count
		var spacing = dist_to_rock/particles_count
		var sine_input = PI/particles_count
		
	#1 to particles count because we dont want the spacing of the first particle to be on the space e.g. 0
		for i in range(1, particles_count+1):
			particles[i-1].global_transform.origin = pos + Vector3(
				spacing*i*cos(angle) + sin(sine_input*i)*dif*scalar*spacing*sin(angle), 
				newy.y*i, 
				spacing*i*sin(angle) - sin(sine_input*i)*dif*scalar*spacing*cos(angle))
