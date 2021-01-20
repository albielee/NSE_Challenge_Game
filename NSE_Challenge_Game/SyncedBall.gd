extends RigidBody2D


var puppet_pos = Vector2()


func _physics_process(delta):
	rset("puppet_pos", position)
	
	puppet_pos = position # To avoid jitter
