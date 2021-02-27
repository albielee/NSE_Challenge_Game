extends Area

export var SIDEFORCE = 20
export var PUSH_POWER = 1200

var rock = null
var rocks = []
var first_push = false
var timer = 4
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
		target_angle = current_target_angle
		
		rock_position = rock.global_transform.origin
		var ideal_location = Vector3(player_position.x + rock.size*sin(-target_angle), 0, player_position.z - rock.size*cos(-target_angle))
		rock.add_force((ideal_location-rock_position).normalized()*5)
		
		if rock_position.distance_to(ideal_location) < rock.size and rock.speed > 2:
			rock.add_force(-rock.linear_velocity*10)
		
		var rotation_angle = wrapf(target_angle - rock.face, -PI/4, PI/4);
		rock.angular_velocity((Vector3.UP * rotation_angle)*5)
		
		if player_position.y+0.7-rock_position.y > 0:
			rock.add_force(Vector3.UP*rock.gravity/0.8)
		else:
			rock.add_force(Vector3.UP*rock.gravity/1.1)

func _on_PullBox_area_entered(area):
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
			if dist < mini and not i.flying: mini = dist
		if (rock==null and mini < 50):
			rock=rockdic[mini]
			rock_position = rock.global_transform.origin
			if mini > rock.size*1.5:
				rock.add_force(-knockback_vector*PUSH_POWER)
			rock.add_force(Vector3.UP*20)
			rock.in_zone(get_parent().playerid) #This is setting the rock to "push mode"
			rock.get_parent().last_mover = get_parent().player_name #assigns player to rock
		for i in rocks:
			if (rock != i):
				i.add_force(-knockback_vector*PUSH_POWER/8)

func update_angle(target_angle_y, player_mouse_angle, player_pos):
	current_target_angle = target_angle_y
	player_mouse = player_mouse_angle
	player_position = player_pos

func release():
	angle_set = false
	first_push = false
	rocks = []
	timer = 4
	if rock != null:
		rock.out_zone() #Set rock directly back to "normal mode"
		rock = null
