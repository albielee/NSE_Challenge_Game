extends Node

# Default game port. Can be any number between 1024 and 49151.
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 4

# Name for my player.
var player_name = "chadlington"
var joined = false
var run_once = true

var available_colours = [0,1,1,1] #Changed server side only
var colours = [Color("0099db"),Color("68386c"),Color("feae34"),Color("3e8948")]
var player_colour_index = 0
var players_colour = {1:0}

# Names for remote players in id:name format.
var players = {}
var players_ready = []

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

# Data from lobby for round settings
var round_time
var round_number


func _process(delta):
	if(joined and run_once):
		if(!get_tree().is_network_server()):
			call_server_get_available_colour()
			run_once = false

# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	rpc_id(id, "register_player", player_name)


# Callback from SceneTree.
func _player_disconnected(id):
	print("my pdisconnecto")
	if has_node("/root/World"): # Game is in progress.
		if get_tree().is_network_server():
			emit_signal("game_error", "Player " + players[id] + " disconnected")
			print("I left")
			end_game()
		else:
			unregister_player(id)
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")


# Lobby management functions.
remote func register_player(new_player_name):
	var id = get_tree().get_rpc_sender_id()
	players[id] = new_player_name
	emit_signal("player_list_changed")
	joined = true


func unregister_player(id):
	players.erase(id)
	available_colours[players_colour[id]] = 1
	players_colour.erase(id)
	emit_signal("player_list_changed")


remote func pre_start_game(spawn_points, roundSettings):
	# Change scene.
#	print(get_tree().get_current_scene() )
	print_tree_pretty()
	#print("EY")
	#get_tree().change_scene("res://Worlds/world.tscn")
	get_tree().get_root().get_node("LobbyWorld").queue_free() 

	var map = roundSettings[0]
	var world = load(map).instance()
	
	get_tree().get_root().add_child(world)
	print_tree_pretty()
	#get_tree().get_root().get_node("LobbyWorld").get_node("Lobby").hide()
	
	var player_scene = load("res://Player/Player.tscn")
	for p_id in spawn_points:
		var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).get_transform().origin
		var player = player_scene.instance()
		player.spawn_position = spawn_pos

		player.set_name(str(p_id)) # Use unique ID as node name.
		player.transform.origin = spawn_pos
		player.set_network_master(p_id) #set unique id as master.
		print(players_colour)
		
		if p_id == get_tree().get_network_unique_id():
			# If node for this peer id, set name.
			player.set_player_name(player_name)
			print(player_colour_index)
			player.set_player_colour(colours[player_colour_index])
		else:
			# Otherwise set name from peer.
			player.set_player_colour(colours[players_colour[p_id]])
			player.set_player_name(players[p_id])
		
		world.get_node("Players").add_child(player)
#		print("this is lafkjndrkjgndxignsdriyfhb")
		print(roundSettings)
		world.get_node("RoundController").round_time = roundSettings[1]
		world.get_node("RoundController").round_number = roundSettings[2]
	
	if not get_tree().is_network_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		post_start_game()


remote func post_start_game():
	get_tree().set_pause(false) # Unpause and unleash the game!


remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == players.size():
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()


func host_game(new_player_name):
	player_name = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)


func join_game(ip, new_player_name):
	var joined = false
	var run_once = true
	player_name = new_player_name
	var client = NetworkedMultiplayerENet.new()
	client.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(client)


func get_player_list():
	return players.values()

func get_player_name():
	return player_name

func begin_game(roundSettings):
	assert(get_tree().is_network_server())
	
	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
	var spawn_points = {}
	spawn_points[1] = 0 # Server in spawn point 0.
	var spawn_point_idx = 1
	for p in players:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1
	# Call to pre-start game with the spawn points.

	for p in players:
		rpc_id(p, "recieve_colours_dic", players_colour)
		rpc_id(p, "pre_start_game", spawn_points, roundSettings)
		
	pre_start_game(spawn_points, roundSettings)

func notify_clients_start_pressed():
	rpc("start_pressed")
	
remote func start_pressed():
	#get_tree().get_root().print_tree()
	get_tree().get_root().get_node("LobbyWorld/Camera").start_travelling()

remote func send_recieve_color(index):
	if(get_tree().is_network_server()):
		var sender_id = get_tree().get_rpc_sender_id()
		print(available_colours)
		available_colours[index]=1
		index = wrapi(index+1, 0, 4)
		
		var found = false
		var error_case = 0
		while(!found):
			if(available_colours[index]):
				found = true
				available_colours[index] = 0
			else:
				index = wrapi(index+1, 0, 4)
			error_case += 1
			if(error_case > 5):
				assert("OH GOD TOO MANY PLAYERS")
				return
		rpc_id(sender_id, "recieve_colour_index", sender_id, index)
		players_colour[sender_id] = index
		for p in players:
			rpc_id(p, "recieve_colours_dic", players_colour)
		print(players_colour)
	
remote func recieve_colour_index(id, index):
	player_colour_index = index

remote func recieve_colours_dic(col_dic):
	players_colour = col_dic
	print(players_colour)

remote func get_available_colour():
	if(get_tree().is_network_server()):
		var i = 0
		var a = 0
		var found = false
		while(!found):
			if(a > 10):
				print("INFINITE LOOP SOMETHING IS GOING WRONG, TOO MANY PLAYERS?")
				break
			a+=1
			if(available_colours[i]):
				available_colours[i] = 0
				found = true
			else:
				i = wrapi(i+1, 0, 4)
		var sender_id = get_tree().get_rpc_sender_id()
		rpc_id(sender_id, "recieve_colour_index", sender_id, i)
		players_colour[sender_id] = i
		for p in players:
			rpc_id(p, "recieve_colours_dic", players_colour)
		print(players_colour)
	
		
func call_server_get_available_colour():
	rpc("get_available_colour")

func call_server_next_colour():
	rpc("send_recieve_color", player_colour_index)

func end_game():
	return
#	if has_node("/root/World"): # Game is in progress.
#		# End it
#		get_node("/root/World").queue_free()
#
#	emit_signal("game_ended")
#	players.clear()
func player_leave_button():
	joined = false
	run_once = true
	player_colour_index = 0
	get_tree().get_network_peer().close_connection()

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
