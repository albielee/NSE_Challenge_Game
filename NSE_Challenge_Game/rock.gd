extends KinematicBody2D

puppet var puppet_pos = Vector2()
puppet var puppet_rotation = rotation

var velocity = Vector2(10,0)

#Sync the rotation and position of this object!
func _physics_process(delta):
	
	
	if not is_network_master():
		position = puppet_pos
		rotation = puppet_rotation
	else:
		rset("puppet_pos", position)
		rset("puppet_rotation", rotation)
	
	var bodies = $Area2D.get_overlapping_bodies()
	var velocity_sum = Vector2()
	for bod in bodies:
		if(bod != self):
			velocity_sum += bod.velocity
	
	move_and_slide(velocity+velocity_sum)
