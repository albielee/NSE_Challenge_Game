extends KinematicBody2D

puppet var puppet_pos = Vector2()
puppet var puppet_rotation = rotation


func _physics_process(delta):
	$StackedSprite.rotation += 0.01
	if not is_network_master():
		position = puppet_pos
		rotation = puppet_rotation
	else:
		rset_unreliable("puppet_pos", position)
		rset_unreliable("puppet_rotation", rotation)

#sync this with all clients otherwise it will just be the host who it is removed for
sync func reset():
	queue_free()

