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

var face = 0

var in_zone = false

var id
var owned_by = ""
var time = 0

var prev_speed = 0
var speed = 0
var next_speed = 0

var buffer = []

var size = 0

onready var hitbox = $Hitbox
onready var playerhitbox = $Hitbox2
onready var p_hitbox = $PlayerHitbox

var last_mover=""

func _ready():
	set_gravity_scale(5)
	set_linear_damp(5)
	add_to_group("rocks")
	size = scale.x
	hitbox.size = size
	r_stats = [get_transform().origin, get_transform().basis.get_euler().y, linear_velocity]

func _physics_process(delta):
	face=get_transform().basis.get_euler().y
	if get_tree().get_network_unique_id() == owned_by:
		update(delta)
	else:
		puppet_update(delta)
		
	#Playing rock slide sound
	if($GroundDetector.is_colliding()):
		if(speed > 0.1):
			if(!$Slide.playing):
				$Slide.play()
				$Slide.unit_db  = speed/10
		else: $Slide.stop()
	else:
		if($Slide.playing):
			$SlideOff.play()
		$Slide.stop()
		if(!$InAir.playing):
			$InAir.play()

func set_id(num):
	id = num

func puppet_update(delta):
	var p = get_transform().origin
	var dir = (r_next_pos-p).normalized()
	var dist = p.distance_to(r_next_pos)
	
	if len(buffer) > 0 and time <= 0:
		prev_speed = r_velocity.length()
		var statstime = buffer.pop_front()
		time += statstime[1]/(len(buffer)+1)
		r_stats = statstime[0]
		r_position = r_stats[0]
		r_rotation = r_stats[1]
		r_velocity = Vector2(r_stats[2].x,r_stats[2].z)
		r_next_pos = r_position + (Vector3(r_velocity.x,0,r_velocity.y) * time)
		
		speed = r_velocity.length()
		next_speed = speed
		
		var interp = 1/1.5
		if speed <= prev_speed:
			if dist > 0.05:
				next_speed = dist + next_speed + (((prev_speed - speed)-next_speed) * interp)
			else: next_speed += ((prev_speed - speed)-next_speed) * interp
		if speed > prev_speed:
			next_speed = prev_speed + speed
	
	#inter fucking polate this shit
	var cur_speed = get_linear_velocity()
	if dist >= 1:
		set_linear_velocity(next_speed*dir*dist)
	else: set_linear_velocity(next_speed*dir)
	
	puppet_rotation(r_rotation,delta)
	
	if time > 0: time -= delta

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
	speed = Vector2(linear_velocity.x, linear_velocity.z).length()
	hitbox.face=get_transform().basis.get_euler().y
	hitbox.speed=speed
	hitbox.linear_velocity=linear_velocity
	if(in_zone):
		hitbox.flying = true
		set_gravity_scale(1)
		set_linear_damp(0.5)
	else:
		if (speed < 5):
			hitbox.flying = false
			set_gravity_scale(5)
			set_linear_damp(5)
		else: hitbox.flying = true

func destroy():
	#the rock has fallen and should be removed from the whole game
	#can't signal this shit, so I'm just calling get_parent()
	if get_tree().get_network_unique_id() == owned_by:
		get_parent().destroy_rock(id)
	
	queue_free()

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
	get_parent().change_owner(id, owned_by)
	in_zone = true

func _on_Rock_body_entered(body):
	if(body.is_in_group("rock") and speed > 16):
		$Hit.play()

func _on_Hitbox2_pushed():
	add_force(playerhitbox.knockback, Vector3.ZERO)
