extends Spatial


var beam_count = 6
var grabbed_rock


func _physics_process(delta):
	#var dist_to_rock = get_global_transform().origin.distance_to(grabbed_rock.get_global_transform().origin)
	
	for i in range(beam_count):
		var particle_beam = get_child(i)
		#particle_beam = 
