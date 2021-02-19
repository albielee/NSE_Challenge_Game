extends Node

var rockdic = {}
var num = 0

var current_time = 0.0
var last_packet_time = 0.0
var elapsed_time = 0.0
var avg = 0.0

var packets = []

remote var r_rockdic = {} setget set_rock_stats

func get_rock_id():
	num += 1
	return num

func _physics_process(delta):
	current_time += delta

func set_rock_stats(dic):
	#how long since the last packet?
	elapsed_time = current_time - last_packet_time
	
	avg = average_packet_time(elapsed_time)
	
	#set this time to be the time the last packet arrived
	last_packet_time = current_time
	r_rockdic = dic
	for rock in get_children():
		if rock.is_in_group("rocks"):
			if not get_tree().get_network_unique_id() == rock.owned_by:
				rock.packet_received(avg)

func average_packet_time(newpacket_elapsed):
	packets.append(newpacket_elapsed)
	if len(packets) > 50:
		packets.remove(0)
	var total = 0.0
	for time in packets:
		total += time
	return total/len(packets)

func create_rock(rock):
	rockdic[rock.id] = rock.get_stats()
	r_rockdic[rock.id] = rock.get_stats()
	add_child(rock)

remote func owner_change(id, player):
	for rock in get_children():
		if rock.is_in_group("rocks"):
			if rock.id == id:
				rock.owned_by = player

func is_host():
	return (get_tree().is_network_server())

func _on_Timer_timeout():
	for rock in get_children():
		if rock.is_in_group("rocks"):
			if get_tree().get_network_unique_id() == rock.owned_by:
				rockdic[rock.id] = rock.get_stats()
	rset_unreliable("r_rockdic", rockdic)
	$SendData.start(1.0/Settings.tickrate)
