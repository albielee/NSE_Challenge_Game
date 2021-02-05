extends Area

export var SIDEFORCE = 20
export var PUSH_POWER = 600

var rock = null
var rocks = []
var first_push = false
var timer = 15
var rock_position = Vector3.ZERO
var player_position = Vector3.ZERO
var player_rock = 0

var knockback_vector = Vector3.ZERO
var rock_push_vector = Vector3.ZERO

var current_target_angle = 0 
var target_angle = 0

var player_mouse = Vector3.ZERO

var angle_set = false

onready var shape = $CollisionShape

func update(mouse_position, player_to_rock):
	if (rock!=null):
		if !angle_set:
			angle_set = true
			target_angle = current_target_angle
		
		if timer > 0:
			timer -= 1
		if timer == 0:
			if(rock.speed < 5):
				release()
				return
		
		player_rock = wrapf(player_to_rock,-PI,PI)
		var fire_vector = Vector3(-sin(player_rock),0,-cos(player_rock))
		rock_push_vector=fire_vector*PUSH_POWER/100
		
		var rotation_angle = wrapf(target_angle - rock.face, -PI/4, PI/4);
		
		rock.angular_velocity((Vector3.UP * rotation_angle)*5)
		rock_position = rock.global_transform.origin
#		rock.add_force(rock_push_vector)
		
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
		
		if sin(player_mouse.y-player_rock+current_target_angle) > 0.1:
			rock.add_force(rightmotion)
			target_angle += SIDEFORCE*0.0005
		elif sin(player_mouse.y-player_rock+current_target_angle) < -0.1:
			rock.add_force(leftmotion)
			target_angle -= SIDEFORCE*0.0005

func _on_PushBox_area_entered(area):
	if not area in rocks:
		rocks.append(area)

func do_push():
	if not first_push:
		first_push = true
		var rockdic = {}
		var mini = 50
		for i in rocks:
			var dist = i.global_transform.origin.distance_to(player_position)
			rockdic[dist] = i
			if dist < mini: mini = dist
		if (rock==null and mini < 50):
			rock=rockdic[mini]
			rock_position = rock.global_transform.origin
			rock.add_force(knockback_vector*PUSH_POWER)
			rock.add_force(Vector3.UP*20)
			rock.in_zone() #This is setting the rock to "push mode"
		for i in rocks:
			if (rock != i):
				i.add_force(knockback_vector*PUSH_POWER/5)

func update_angle(target_angle_y, player_mouse_angle, player_pos):
	current_target_angle = target_angle_y
	player_mouse = player_mouse_angle
	player_position = player_pos

func release():
	angle_set = false
	first_push = false
	rocks = []
	timer = 15
	if rock != null:
		rock.out_zone() #Set rock directly back to "normal mode"
		rock = null
