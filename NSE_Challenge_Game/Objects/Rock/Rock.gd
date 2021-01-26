extends RigidBody

#Positional data
remote var remote_position = Vector3.ZERO
remote var remote_rotation = 0.0

var i = 1


func _physics_process(delta):
	if(get_tree().is_network_server()):
		if(mode != MODE_RIGID):
			set_mode(RigidBody.RIGID)
	else:
		#This will allow the setting of positional arguments
		if(mode != MODE_KINEMATIC):
			set_mode(RigidBody.MODE_KINEMATIC)
		translation = remote_position
		set_rotation(Vector3(0,remote_rotation,0))

func _on_SendData_timeout():
	if(get_tree().is_network_server()):
		rset_unreliable("remote_rotation", get_rotation().y)
		rset_unreliable("remote_position", get_transform().origin)
		$SendData.start(1.0/Settings.tickrate)

#sync this with all clients otherwise it will just be the host who it is removed for
sync func reset():
	queue_free()

