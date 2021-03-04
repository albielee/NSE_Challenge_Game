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

var id
var owned_by = ""
var time = 0

var prev_speed = 0
var speed = 0
var next_speed = 0

var buffer = []

onready var hitbox = $Hitbox
onready var playerhitbox = $Hitbox2
onready var p_hitbox = $PlayerHitbox

var last_mover=""
var location = Vector3.ZERO
var _delta = 0.0
var current_rotation = Vector3.ZERO
var face = 0
var size = 0

func _ready():
	set_gravity_scale(5)
	set_linear_damp(5)
	add_to_group("rocks")
	r_stats = [get_transform().origin, get_transform().basis.get_euler().y, linear_velocity]

func _physics_process(delta):
	handle_stats(delta)
	if get_tree().get_network_unique_id() == owned_by:
		update(delta)
	else:
		puppet_update(delta)
	sounds()

func handle_stats(delta):
	face = get_transform().basis.get_euler().y
	location = get_transform().origin
	current_rotation = rotation
	_delta = delta
	size = scale.x
	hitbox.pos = location
	hitbox.size = size
	hitbox.linear_velocity = linear_velocity
	hitbox.owned_by = owned_by
	playerhitbox.size = scale.x
	playerhitbox.pos = location

func _integrate_forces(state):
	if get_tree().get_network_unique_id() != owned_by:
		var target = Vector3.UP * wrapf(r_rotation-face, -PI, PI)
		rotation = current_rotation + (target*(400*_delta/30))

#PUPPET UPDATE
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
		r_velocity = r_stats[2]
		r_next_pos = r_position + (r_velocity * time)
	
	if r_next_pos != Vector3.ZERO:
		var d = r_next_pos-location
		transform.origin = location + (d * 20 * _delta)
	
	puppet_rotation(r_rotation,delta)
	set_linear_velocity(r_velocity)
	
	if time > 0: time -= delta

func puppet_rotation(target, delta):
	var angular_veloc =  Vector3.UP * wrapf(target-get_transform().basis.get_euler().y, -PI, PI);
	
	set_angular_velocity(angular_veloc*800*delta)

func packet_received(average_time):
	#ain't exactly pretty. TODO: Fix this with signals instead of calls
	if id in get_parent().r_rockdic and owned_by != get_tree().get_network_unique_id():
		build_buffer(get_parent().r_rockdic[id], average_time)

func build_buffer(stats, avg):
	buffer.push_back([stats,avg])

#OWNER UPDATE
func update(delta):
	speed = sqrt(pow(linear_velocity.x, 2) + pow(linear_velocity.z,2))
	if buffer!=[]: buffer = []
	speed = Vector2(linear_velocity.x, linear_velocity.z).length()
	hitbox.face=get_transform().basis.get_euler().y
	hitbox.speed=speed
	if(in_zone):
		hitbox.flying = true
		set_gravity_scale(1)
		set_linear_damp(0.5)
	else:
		if (speed < 1):
			hitbox.flying = false
			set_gravity_scale(5)
			set_linear_damp(5)
		else: hitbox.flying = true
	remote_update()

func remote_update():
	#Although currently owned, there should be preparations for when it is a puppet once more
	r_position = get_transform().origin
	r_rotation = get_transform().basis.get_euler().y
	r_velocity = linear_velocity
	r_next_pos = r_position

#SOUNDS
func sounds():
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

#NETWORK STUFF
func destroy():
	#the rock has fallen and should be removed from the whole game
	#can't signal this shit, so I'm just calling get_parent()
	if get_tree().get_network_unique_id() == owned_by:
		get_parent().destroy_rock(id)
	
	queue_free()

func get_stats():
	return [get_transform().origin, get_transform().basis.get_euler().y, linear_velocity]

sync func reset():
	queue_free()

func set_id(num):
	id = num

func set_owner(pid):
	if owned_by != pid:
		buffer = [] 
		owned_by = pid
		get_parent().change_owner(id, owned_by)

#HITBOX SIGNALS
func _on_Hitbox_pushed():
	add_force(hitbox.knockback, Vector3.ZERO)

func _on_Hitbox_spun():
	set_angular_velocity(hitbox.angular)

func _on_Hitbox_nozone():
	in_zone = false

func _on_Hitbox_zone():
	set_owner(hitbox.owned_by)
	in_zone = true

func _on_Rock_body_entered(body):
	if(body.is_in_group("rock") and speed > 16):
		$Hit.play()
	if body.is_in_group("rock") and body.speed > speed:
		set_owner(body.owned_by)

func _on_Hitbox2_pushed():
	add_force(playerhitbox.knockback, Vector3.ZERO)
