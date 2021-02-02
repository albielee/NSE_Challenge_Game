extends Area

var knockback_vector = Vector3.ZERO
var rock = null
var playerorientation = Vector3.ZERO
var mouseang = Vector3.ZERO
var force = 0
var target_angle = Vector3.ZERO

onready var shape = $CollisionShape

func update(mouse_position, player_position):
	if (rock!=null):
		var rotation_angle = wrapf(target_angle - rock.face, -PI/4, PI/4);
		
		mouseang = Vector3.UP * rotation_angle;
		
		rock.angular_velocity(mouseang*5)
		var rock_position = rock.global_transform.origin
		if player_position.y+0.2-rock_position.y > 0:
			rock.add_force(Vector3.UP*rock.gravity)
		else:
			rock.add_force(Vector3.UP*rock.gravity/1.1)

		
		#mouse adjustment time. This won't be easy.
		var flatrock = Vector2(rock_position.x,rock_position.z)
		var flatmouse = Vector2(mouse_position.x,mouse_position.z)
		var flatplayer = Vector2(player_position.x,player_position.z)
		
		var rocktomouse = flatrock-flatmouse
		var playertorock = flatplayer-flatrock
		
		var dotprod = rocktomouse.dot(playertorock)
		var cosa = dotprod / rocktomouse.length()*playertorock.length()
#		var length = cosa*rocktomouse
#		force = sin(cosa)*rocktomouse
		print(cosa)
		

func _on_PushBox_area_entered(area):
	if (rock==null):
		rock=area
		
		rock.add_force(Vector3.UP*20)
		#rock.add_force(knockback_vector)
		rock.angular_velocity(mouseang*5)
		rock.in_zone() #This is setting the rock to "push mode"
	else:
		area.add_force(knockback_vector/2)

func update_mouse_angle(target_angle_y):
	target_angle = target_angle_y

func release():
	if rock != null:
		rock.out_zone() #Set rock directly back to "normal mode"
		rock = null
