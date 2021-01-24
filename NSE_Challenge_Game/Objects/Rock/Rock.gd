extends RigidBody2D

#Positional data
remote var remote_position = Vector2.ZERO
remote var remote_rotation = 0.0

func _ready():
	$StackedSprite.load_animation("rock","res://Assets/Rock/rock.png",1,20)

func _physics_process(delta):
	if(get_tree().is_network_server()):
		set_mode(RigidBody2D.MODE_RIGID)
		
	else:
		#This will allow the setting of positional arguments
		set_mode(RigidBody2D.MODE_KINEMATIC)
		position = remote_position
		rotation = remote_rotation
		
	#Play rock anim
	if($StackedSprite.playing_animation == ""):
		$StackedSprite.play_animation("rock",1)

func _on_SendData_timeout():
	if(get_tree().is_network_server()):
		rset_unreliable("remote_rotation", rotation)
		rset_unreliable("remote_position", position)
		$SendData.start(1.0/Settings.tickrate)

#sync this with all clients otherwise it will just be the host who it is removed for
sync func reset():
	queue_free()

