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
	
	$beam_0.emitting = true
	$beam_1.emitting = true
	$beam_2.emitting = true
	$beam_3.emitting = true
	$beam_4.emitting = true
	$beam_5.emitting = true
	$beam_6.emitting = true
	$beam_7.emitting = true
	$beam_8.emitting = true
	$beam_9.emitting = true
	$beam_10.emitting = true
	$beam_11.emitting = true
	$beam_12.emitting = true
	$beam_13.emitting = true
	$beam_14.emitting = true

func stop_beam():
	active = false
	$beam_0.emitting = false
	$beam_1.emitting = false
	$beam_2.emitting = false
	$beam_3.emitting = false
	$beam_4.emitting = false
	$beam_5.emitting = false
	$beam_6.emitting = false
	$beam_7.emitting = false
	$beam_8.emitting = false
	$beam_9.emitting = false
	$beam_10.emitting = false
	$beam_11.emitting = false
	$beam_12.emitting = false
	$beam_13.emitting = false
	$beam_14.emitting = false



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
