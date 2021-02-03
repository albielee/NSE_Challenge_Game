extends Area

var knockback_vector = Vector3.ZERO
var rock = null
var playerorientation = Vector3.ZERO
var mouseang = Vector3.ZERO
var force = 0
var target_angle = 0
var current_mouse_angle = Vector3.ZERO
var player_mouse = Vector3.ZERO
var rock_position = Vector3.ZERO
var power = 0
var pushed = false

onready var shape = $CollisionShape

func update(mouse_position, player_position):
	if (rock!=null):
		var rotation_angle = wrapf(target_angle - rock.face, -PI/4, PI/4);
		
		mouseang = Vector3.UP * rotation_angle;
		
		rock.angular_velocity(mouseang*5)
		rock_position = rock.global_transform.origin
		if pushed != true:
			pushed=true
			rock.add_force(knockback_vector)
		
		if player_position.y+0.2-rock_position.y > 0:
			rock.add_force(Vector3.UP*rock.gravity)
		else:
			rock.add_force(Vector3.UP*rock.gravity/1.1)
		
		#mouse adjustment time. This won't be easy.
		#What we want, SPECIFICALLY, is the angle between the line from:
		#playerface to rock (
		#and the line from playerface to mouse (player_mouse.y)
		
		if sin(player_mouse.y) > 0.1:
			print('pushleft')
		elif sin(player_mouse.y) < -0.1:
			print('pushright')
		else: print('push straight')

func _on_PushBox_area_entered(area):
	if (rock==null):
		rock=area
		rock_position = rock.global_transform.origin
		rock.add_force(Vector3.UP*20)
		rock.angular_velocity(mouseang*5)
		rock.in_zone() #This is setting the rock to "push mode"
	else:
		area.add_force(knockback_vector/2)

func update_angle(target_angle_y, player_mouse_angle):
	target_angle = target_angle_y
	var curang = wrapf(target_angle_y,-PI,PI)
	var fire_angle = Vector3(-sin(curang),0,-cos(curang))
	knockback_vector=fire_angle*power
	
	player_mouse = player_mouse_angle

func release():
	if rock != null:
		pushed = false
		rock.out_zone() #Set rock directly back to "normal mode"
		rock = null
