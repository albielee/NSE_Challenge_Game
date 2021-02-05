extends RigidBody

#Positional data
remote var remote_position = Vector3.ZERO
remote var remote_rotation = 0.0

var in_zone = false
var speed = 0

onready var hitbox = $Hitbox

var i = 1

func _ready():
	set_linear_damp(5)

func _physics_process(delta):
	if(get_tree().is_network_server()):
		if(mode != MODE_RIGID):
			set_mode(RigidBody.RIGID)
		speed = sqrt(pow(linear_velocity.x, 2) + pow(linear_velocity.z,2))
		hitbox.face=get_transform().basis.get_euler().y
		hitbox.speed=speed
		if(in_zone):
			set_linear_damp(0.5)
		else:
			if (speed < 1):
				set_linear_damp(5)
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

func _on_Hitbox_pushed():
	add_force(hitbox.knockback, Vector3.ZERO)
	
func _on_Hitbox_spun():
	set_angular_velocity(hitbox.angular)


func _on_Hitbox_nozone():
	in_zone = false

func _on_Hitbox_zone():
	in_zone = true

