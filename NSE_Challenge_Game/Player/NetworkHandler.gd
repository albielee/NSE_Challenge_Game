extends Spatial

#dead data
remote var remote_dead = false

onready var rock_network_handler = get_node("/root/World/RockNetworkHandler")

func is_current_player():
	return (is_network_master() and !remote_dead)

func is_host():
	return (get_tree().is_network_server())
	
func get_cam():
	return get_tree().get_nodes_in_group("Camera")[0]

func all_summon_rock(rock_name, rock_pos, orientation):
	rpc("summon_rock", rock_name, rock_pos, get_tree().get_network_unique_id(), orientation)

sync func summon_rock(rock_name, rock_pos, by_who, rock_orientation):
	var rock = preload("res://Objects/Rock/Rock2.tscn").instance()
	
	rock.set_name(rock_name)
	rock.owned_by = by_who
	
	rock_network_handler.create_rock(rock, rock_pos, rock_orientation)

func reset():
	#bring player back to life
	remote_dead = false
	#bring player back to spawn position
