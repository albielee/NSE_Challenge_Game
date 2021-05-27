extends Node

export var ROCK_SIZE = 2.0

var num = 0

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

func create_rock(rock, position, orientation, size = ROCK_SIZE):
	rock.set_id(get_rock_id())
	rock.rotation = Vector3.UP*orientation
	if size == ROCK_SIZE:
		rock.scale = Vector3(ROCK_SIZE,ROCK_SIZE,ROCK_SIZE)
	else: rock.scale = Vector3(size,size,size)
	rock.translation = position
	
	rockdic[rock.id] = rock.get_positionals()
	add_child(rock)
#	if is_host():
#		rock.be_summoned()

func destroy_rock(id):
	rockdic.erase(id)

func is_host():
	return (get_tree().is_network_server())
