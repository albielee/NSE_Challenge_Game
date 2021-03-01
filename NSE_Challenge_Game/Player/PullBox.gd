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

func update(mouse_position, player_position):
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
		
		if sin(player_mouse.y-player_rock+current_target_angle) > 0.1:
			rock.add_force(rightmotion)
			target_angle += SIDEFORCE*0.00075
		elif sin(player_mouse.y-player_rock+current_target_angle) < -0.1:
			rock.add_force(leftmotion)
			target_angle -= SIDEFORCE*0.00075
		else: side_velocity = 0

func _on_PullBox_area_entered(area):
	if not area in rocks:
		rocks.append(area)

func do_pull():
	if not first_push:
		first_push = true
		var rockdic = {}
		var mini = 50
		for i in rocks:
			if(i != null):
				var dist = i.global_transform.origin.distance_to(player_position)
				rockdic[dist] = i
				if dist < mini and not (i.flying): mini = dist
		if (rock==null and mini < 50):
			rock=rockdic[mini]
			rock.in_zone(get_parent().playerid) #This is setting the rock to "being owned"
			rock_position = rock.pos
			if mini > rock.size*1.5:
				rock.add_force(-knockback_vector*PUSH_POWER)
			rock.add_force(Vector3.UP*20)
			rock.get_parent().last_mover = get_parent().player_name #assigns player to rock
		for i in rocks:
			if (rock != i):
				i.add_force(-knockback_vector*PUSH_POWER/8)
		if rock == null:
			first_push = false

func update_angle(target_angle_y, player_mouse_angle):
	current_target_angle = target_angle_y
	
	player_mouse = player_mouse_angle

func release():
	angle_set = false
	if rock != null:
		rock.out_zone() #Set rock directly back to "normal mode"
		rock = null
