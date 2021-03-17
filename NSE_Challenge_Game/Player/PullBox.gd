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
var kn = Vector3.ZERO

var current_target_angle = 0 
var target_angle = 0

var player_mouse = Vector3.ZERO

var speed_from_player = 0

var angle_set = false

var affectedrocks = []

onready var shape = $CollisionShape

func update(mouse_position, player_to_rock):
	if (rock!=null):
		speed_from_player = kn.dot(rock.linear_velocity)
		target_angle = current_target_angle
		
		rock_position = rock.global_transform.origin
		var rs = (rock.size/4)+1.2
		var ideal_location = Vector3(player_position.x + rs*sin(-target_angle), 0, player_position.z - rs*cos(-target_angle))
		rock.add_force((ideal_location-rock_position).normalized()*30)
		
		if rock_position.distance_to(ideal_location) < rock.size:
			if rock.speed > 2:
				rock.add_force(Vector3(-rock.linear_velocity.x, 0, -rock.linear_velocity.z)*10)
				
		var heighttoolow = player_position.y+0.9+(rock.size/4)-rock_position.y
		if heighttoolow > 0:
			rock.add_force(heighttoolow*50*Vector3.UP)
		
#		if  heighttoolow > -2:
#			rock.add_force(Vector3.UP*rock.gravity/0.1)
#		else:
#			rock.add_force(Vector3.UP*rock.gravity/5)
		
		var rotation_angle = wrapf(target_angle - rock.face, -PI/4, PI/4);
		rock.angular_velocity((Vector3.UP * rotation_angle)*5)

func _on_PullBox_area_entered(area):
	if not area in rocks:
		rocks.append(area)

func do_pull():
	if not first_push:
		kn = knockback_vector.normalized()
		first_push = true
		var rockdic = {}
		var mini = 50
		for i in rocks:
			if(i != null):
				var dist = i.global_transform.origin.distance_to(player_position)
				rockdic[dist] = i
				if dist < mini and i.real:
					if not i.flying: mini = dist
					if i.last_mover == get_parent().player_name: mini = dist
		if (rock==null and mini < 50):
			rock=rockdic[mini]
			rock_position = rock.global_transform.origin
			if mini > rock.size*1.5:
				rock.add_force(-knockback_vector*PUSH_POWER)
			rock.add_force(Vector3.UP*20)
			rock.in_zone(get_parent().playerid) #This is setting the rock to "push mode"
			rock.get_parent().last_mover = get_parent().player_name #assigns player to rock
		for i in rocks:
			if (rock != i) and i != null and not i in affectedrocks:
				affectedrocks.append(i)
				if i.real: 
					if i.last_mover == get_parent().player_name or i.last_mover == '' or i.still:
						i.add_force(-knockback_vector*PUSH_POWER/3)
		if rock == null:
			first_push = false

func update_angle(target_angle_y, player_mouse_angle, player_pos):
	current_target_angle = target_angle_y
	player_mouse = player_mouse_angle
	player_position = player_pos

func release():
	angle_set = false
	first_push = false
	rocks = []
	affectedrocks = []
	timer = 4
	if rock != null:
		rock.out_zone()
		rock = null
