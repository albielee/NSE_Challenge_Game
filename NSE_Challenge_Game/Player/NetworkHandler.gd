extends Spatial

#This class holds mostly server data stuff. Go to PlayerController to add cool
#new player stuff (eventually)

#Input
puppet var puppet_control_movement = Vector2.ZERO
puppet var puppet_control_pushpull = 0.0
puppet var puppet_control_summon = 0.0
puppet var puppet_control_grab = 0.0
puppet var puppet_control_dash = 0.0
puppet var puppet_mouse_position = Vector3.ZERO
puppet var puppet_controls = [puppet_control_movement, puppet_control_pushpull, puppet_control_summon,
	puppet_control_grab, puppet_control_dash, puppet_mouse_position]

#Positional data
remote var remote_position = Vector3.ZERO
remote var remote_rotation = Vector3.ZERO
remote var remote_animation = "idle"
remote var remote_velocity = Vector3.ZERO

remote var remote_stats = [remote_position, remote_rotation, 
remote_animation, remote_velocity] setget received_packet

#dead data
remote var remote_dead = false

signal packet_received

var velocity = Vector3.ZERO
var rock_summoned = false
var dead = false

onready var spawn_position = get_parent().spawn_position
onready var rock_network_handler = get_node("/root/World/RockNetworkHandler")
var old_position = Vector3.ZERO

func update_stats():
	return remote_stats

func received_packet(stats):
	remote_stats=stats
	emit_signal("packet_received")

func is_current_player():
	return (is_network_master() and !remote_dead)

func is_host():
	return (get_tree().is_network_server())
	
func get_cam():
	return get_tree().get_nodes_in_group("Camera")[0]

func all_summon_rock(rock_name, rock_pos, rock_size):
	rpc("summon_rock", rock_name, rock_pos, rock_size, get_tree().get_network_unique_id())

sync func summon_rock(rock_name, rock_pos, rock_size, by_who):
	var rock = preload("res://Objects/Rock/Rock2.tscn").instance()
	rock.set_id(rock_network_handler.get_rock_id())
	
	rock.set_name(rock_name)
	rock.translation = rock_pos
	rock.scale = Vector3(rock_size,rock_size,rock_size)
	rock.owned_by = by_who

	rock_network_handler.create_rock(rock)

func timeout(cur_rotation,cur_position,cur_animation,cur_velocity):
	if(is_current_player()):
		#Send off players movement
		rset_unreliable("remote_stats", [cur_rotation, cur_position, cur_animation, cur_velocity])
	$SendData.start(1.0/Settings.tickrate)

func reset():
	#bring player back to life
	remote_dead = false
	#bring player back to spawn position
	get_parent().transform.origin = spawn_position
	get_parent().state=0
