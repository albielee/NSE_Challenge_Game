extends RigidBody

#Positional data
remote var r_position = Vector3.ZERO
remote var r_rotation = 0.0
remote var r_velocity = Vector3.ZERO
remote var r_stats = [r_position,r_rotation,r_velocity]
var r_next_pos = Vector3.ZERO

var cur_position = Vector3.ZERO
var cur_rotation = 0.0
var cur_velocity = Vector3.ZERO

var in_zone = false
var speed = 0
var id
var owned_by = ""

var buffer = []

onready var hitbox = $Hitbox

var last_mover=""

func _ready():
	set_linear_damp(5)
	add_to_group("rocks")
	r_stats = [get_transform().origin, get_transform().basis.get_euler().y, linear_velocity]

func _physics_process(delta):
	if get_tree().get_network_unique_id() == owned_by:
		update(delta)
	else:
		puppet_update(delta)

func set_id(num):
	id = num

func puppet_update(delta):
	var time = 0
	if len(buffer) > 0:
		var statstime = buffer.pop_front()
		time = statstime[1]
		r_stats = statstime[0]
		r_position = r_stats[0]
		r_rotation = r_stats[1]
		r_velocity = r_stats[2]
		r_next_pos = r_position + (r_velocity * time)
	
	var p = get_transform().origin
	var dir = (r_next_pos-p).normalized()
	var dist = p.distance_to(r_next_pos)
	var speed = r_velocity.length()
	
	if time > 0: 
		var puppet_speed = dist / time
		
		#inter fucking polate this shit
		var cur_speed = get_linear_velocity()
		var goal_speed = puppet_speed*dir
		set_linear_velocity(cur_speed.linear_interpolate(goal_speed,delta/time))
	
	puppet_rotation(r_rotation,delta)

func puppet_rotation(target, delta):
	var angular_veloc =  Vector3.UP * wrapf(target-get_transform().basis.get_euler().y, -PI, PI);
	
	set_angular_velocity(angular_veloc*800*delta)

func packet_received(average_time):
	#ain't exactly pretty. TODO: Fix this with signals instead of calls
	if id in get_parent().r_rockdic:
		build_buffer(get_parent().r_rockdic[id], average_time)

func build_buffer(stats, avg):
	buffer.push_back([stats,avg])

func update(delta):
	speed = sqrt(pow(linear_velocity.x, 2) + pow(linear_velocity.z,2))
	hitbox.face=get_transform().basis.get_euler().y
	hitbox.speed=speed
	if(in_zone):
		hitbox.flying = true
		set_linear_damp(0.5)
	else:
		if (speed < 1):
			hitbox.flying = false
			set_linear_damp(5)
		else: hitbox.flying = true

func owner_switch():
	get_parent().switch_owner(self)

func get_stats():
	return [get_transform().origin, get_transform().basis.get_euler().y, linear_velocity]

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
	owned_by=hitbox.owned_by
	in_zone = true
	owner_switch()

func _on_Rock_body_entered(body):
	if body.is_in_group("player"):
		owned_by = body.playerid
		owner_switch()
