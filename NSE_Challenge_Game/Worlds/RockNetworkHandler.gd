extends Node

var ownerdic = {}
var destroylist = []
var num = 0
var to_add_to_rockdic = {}

var current_time = 0.0
var last_packet_time = 0.0
var elapsed_time = 0.0
var avg = 0.0

var packets = []

sync var rockdic = {}

func get_rock_id():
	num += 1
	return num

func _physics_process(delta):
	if is_host():
		for rock in get_children():
			if rock.is_in_group("rocks"):
				rockdic[rock.id] = rock.get_positionals()
		rset_unreliable("rockdic", rockdic)

func rock_exists(id):
	return id in rockdic.keys()

func get_rock_stats(id):
	return rockdic[id]

func create_rock(rock, position):
	rock.translation = position
	rockdic[rock.id] = rock.get_positionals()
	add_child(rock)
	if is_host():
		rock.be_summoned()

func destroy_rock(id):
	rockdic.erase(id)

func is_host():
	return (get_tree().is_network_server())
