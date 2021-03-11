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
var real = true
var timebeenfake = 0

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
var resize = false
var still = true

func _ready():
	set_gravity_scale(5)
	set_linear_damp(5)
	set_mass(80)
	add_to_group("rocks")
	r_stats = [get_transform().origin, get_transform().basis.get_euler().y, linear_velocity]

func _physics_process(delta):
	if get_parent().is_host():
		update(delta)
	else:
		puppet_update(delta)
	sounds()

func handle_pstats(delta):
	face = get_transform().basis.get_euler().y
	location = get_transform().origin
	current_rotation = rotation
	_delta = delta

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
	hitbox.real = real
	playerhitbox.size = scale.x
	playerhitbox.pos = location

func _integrate_forces(state):
	if resize:
		scale = Vector3(size,size,size)
		resize = false
	if not get_tree().is_network_server():
		var target = Vector3.UP * wrapf(r_rotation-face, -PI, PI)
		rotation = current_rotation + (target*(400*_delta/30))
		if r_next_pos != Vector3.ZERO:
			var d = r_next_pos-location
			transform.origin = location + (d * 20 * _delta)

#PUPPET UPDATE
func puppet_update(delta):
	handle_pstats(delta)
	if get_parent().rock_exists(id):
		r_stats = get_parent().get_rock_stats(id)
	else: destroy()
	r_position = r_stats[0]
	r_rotation = r_stats[1]
	r_velocity = r_stats[2]
	r_next_pos = r_position + (r_velocity * delta)

#OWNER UPDATE
func update(delta):
	handle_stats(delta)
	if real == false:
		if global_transform.origin.y >= -0.26 + self.size/2:
			real = true
			set_axis_lock(PhysicsServer.BODY_AXIS_ANGULAR_X,false)
			set_axis_lock(PhysicsServer.BODY_AXIS_ANGULAR_Y,false)
			set_axis_lock(PhysicsServer.BODY_AXIS_ANGULAR_Z,false)
			set_collision_layer_bit(1, true)
		else: 
			timebeenfake += 1
			add_force(Vector3.UP*(100+(timebeenfake*timebeenfake)/10)*get_mass(),Vector3.ZERO)
	if buffer!=[]: buffer = []
	speed = Vector2(linear_velocity.x, linear_velocity.z).length()
	if speed > 0: still = false
	else: still = true
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
	if get_tree().is_network_server():
		get_parent().destroy_rock(id)
	queue_free()

func get_positionals():
	return [get_transform().origin, get_transform().basis.get_euler().y, linear_velocity]

sync func reset():
	queue_free()

func set_id(num):
	id = num

func be_summoned():
	real = false
	set_axis_lock(PhysicsServer.BODY_AXIS_ANGULAR_X,true)
	set_axis_lock(PhysicsServer.BODY_AXIS_ANGULAR_Y,true)
	set_axis_lock(PhysicsServer.BODY_AXIS_ANGULAR_Z,true)
	set_collision_mask_bit(1,false)

#HITBOX SIGNALS
func _on_Hitbox_pushed():
	add_force(hitbox.knockback*get_mass(), Vector3.ZERO)

func _on_Hitbox_spun():
	set_angular_velocity(hitbox.angular)

func _on_Hitbox_nozone():
	in_zone = false

func _on_Hitbox_zone():
	in_zone = true

func _on_Rock_body_entered(body):
	if(body.is_in_group("rock") and speed > 8):
		$Hit.play()

func _on_Hitbox2_pushed():
	add_force(playerhitbox.knockback, Vector3.ZERO)

func _on_Hitbox_growing():
	destroy()
