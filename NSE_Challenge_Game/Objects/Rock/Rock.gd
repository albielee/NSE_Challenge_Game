extends KinematicBody2D

puppet var puppet_pos = Vector2()
puppet var puppet_rotation = rotation

func _physics_process(delta):
	if not is_network_master():
		position = puppet_pos
		rotation = puppet_rotation
	else:
		rset("puppet_pos", position)
		rset("puppet_rotation", rotation)

	

