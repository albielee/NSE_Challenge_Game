extends Spatial

#This class holds mostly server data stuff. Go to PlayerController to add cool
#new player stuff (eventually)

#Input
puppet var puppet_control_movement = Vector2.ZERO
puppet var puppet_control_pushpull = 0.0
puppet var puppet_control_summon = 0.0
puppet var puppet_mouse_angle = Vector3.ZERO
puppet var puppet_current_angle = Vector3.ZERO
puppet var controls = [puppet_control_movement, puppet_control_pushpull, puppet_control_summon,
	puppet_mouse_angle]

#Positional data
remote var remote_position = Vector3.ZERO
remote var remote_rotation = Vector3.ZERO
remote var remote_animation = "idle"

#dead data
remote var remote_dead = false

var velocity = Vector3.ZERO
var rock_summoned = false
var dead = false

var spawn_position = Vector3.ZERO
var old_position = Vector3.ZERO
	
func update_controls():
	#set controls to whatever was set last time
	return [puppet_control_movement, puppet_control_pushpull, puppet_control_summon,puppet_mouse_angle]

func is_current_player():
	return (is_network_master() and !remote_dead)

func current_player(controls):
	#update current controls because the right player is doing it
	puppet_control_movement = controls[0] 
	puppet_control_pushpull = controls[1] 
	puppet_control_summon   = controls[2]
	puppet_mouse_angle      = controls[3]

func is_host():
	return (get_tree().is_network_server())
	
func get_cam():
	return get_tree().get_nodes_in_group("Camera")[0]

func all_summon_rock(rock_name, rock_pos):
	rpc("summon_rock", rock_name, rock_pos , get_tree().get_network_unique_id())

sync func summon_rock(rock_name, rock_pos, by_who):
	var rock = preload("res://Objects/Rock/Rock.tscn").instance()
	rock.set_name(rock_name)
	
	rock.translation = rock_pos

	get_node("../..").add_child(rock)

func timeout(cur_rotation,cur_position,cur_animation):
	if(is_host()):
		#Send rotational and positional data
		rset_unreliable("remote_rotation", cur_rotation)
		rset_unreliable("remote_position", cur_position)
		rset_unreliable("remote_animation", cur_animation)
		rset("remote_dead", remote_dead)
	else:
		if(is_current_player()):
			#Send off players movement
			rset("puppet_control_movement", puppet_control_movement)
			#send pushpull
			rset("puppet_control_pushpull", puppet_control_pushpull)
			rset("puppet_control_summon", puppet_control_summon)
			rset("puppet_mouse_angle", puppet_mouse_angle)
	$SendData.start(1.0/Settings.tickrate)

#Called when the player enters the void area
#func fall_state():
#	state = FALL;
#	#anim, falling motion, destroy player
#
#	#on animation finished, destroy player
#	state = DEATH;
#	death_state()
	

#func death_state():
#	#move the players away - this is easier than destroying the client and respawning them
#	#if we do multiple rounds
#	pc.set_mode(RigidBody.MODE_KINEMATIC)
#	translation = Vector3.ZERO

master func reset():
#	pc.set_mode(RigidBody.MODE_KINEMATIC)
	
	#bring player back to life
	remote_dead = false
	print("RESET")
	#bring player back to spawn position
	translation = spawn_position
#	state = MOVE
	
#	pc.set_mode(RigidBody.MODE_RIGID)
