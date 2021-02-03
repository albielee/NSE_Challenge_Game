extends Area

var knockback_vector = Vector3.ZERO
var rock_push_vector = Vector3.ZERO
var rock = null
var playerorientation = Vector3.ZERO
var mouseang = Vector3.ZERO
var force = 0
var current_target_angle = 0 
var target_angle = 0
var current_mouse_angle = Vector3.ZERO
var player_mouse = Vector3.ZERO
var rock_position = Vector3.ZERO
var player_rock = 0
var power = 0
var side_velocity = 0
var angle_set = false
var SIDEFORCE = 20

onready var shape = $CollisionShape

func update(mouse_position, player_position, player_current):
	if (rock!=null):
		if !angle_set:
			angle_set = true
			target_angle = current_target_angle
		
		player_rock = wrapf(current_target_angle,-PI,PI)
		var fire_vector = Vector3(-sin(player_rock),0,-cos(player_rock))
		rock_push_vector=fire_vector*power/100
		
		var rotation_angle = wrapf(target_angle - rock.face, -PI/4, PI/4);
		
		mouseang = Vector3.UP * rotation_angle;
		rock.angular_velocity(mouseang*5)
		rock_position = rock.global_transform.origin
		rock.add_force(rock_push_vector)
		
		if player_position.y+0.2-rock_position.y > 0:
			rock.add_force(Vector3.UP*rock.gravity)
		else:
			rock.add_force(Vector3.UP*rock.gravity/1.1)
		
		#mouse adjustment time. This won't be easy.
		#What we want, SPECIFICALLY, is the angle between the line from:
		#playerface to rock (rpv?)
		#and the line from playerface to mouse (player_mouse.y)
		
		var rpv = rock_push_vector.normalized()
		var leftmotion = Vector3(-rpv.z, 0, rpv.x)*SIDEFORCE
		var rightmotion = Vector3(rpv.z, 0, -rpv.x)*SIDEFORCE
		
		if sin(player_mouse.y-player_rock+player_current) > 0.1:
			rock.add_force(rightmotion)
			target_angle += SIDEFORCE*0.00075
		elif sin(player_mouse.y-player_rock+player_current) < -0.1:
			rock.add_force(leftmotion)
			target_angle -= SIDEFORCE*0.00075
		else: side_velocity = 0

func _on_PushBox_area_entered(area):
	if (rock==null):
		rock=area
		rock_position = rock.global_transform.origin
		rock.add_force(knockback_vector)
		rock.add_force(Vector3.UP*20)
		rock.in_zone() #This is setting the rock to "push mode"
	elif (rock != area):
		area.add_force(knockback_vector/2)

func update_angle(target_angle_y, player_mouse_angle):
	current_target_angle = target_angle_y
	
	player_mouse = player_mouse_angle

func release():
	angle_set = false
	if rock != null:
		rock.out_zone() #Set rock directly back to "normal mode"
		rock = null
