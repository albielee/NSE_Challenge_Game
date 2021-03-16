extends Control

onready var countdown_sprites = [$Number3,$Number2,$Number1]
onready var win_message = get_node("WinSprite")
onready var lose_message = get_node("LoseSprite")


var fall_map = [
	[1,1,1,1,1,1,1,1],
	[1,2,2,2,2,2,2,1],
	[1,2,2,0,0,2,2,1],
	[1,2,2,0,0,2,2,1],
	[1,2,2,0,0,2,2,1],
	[1,2,2,0,0,2,2,1],
	[1,2,2,2,2,2,2,1],
	[1,1,1,1,1,1,1,1]
]

var fall_time = 5
var fall_timer


var slide_max_speed = 50
var slide_speed = 20
var slide_accel = 30
var scoreboard_sliding = false
var scoreboard_open = false
var shake = 0
var colour_splash_modulate = Color()
var player_scoreboxes = {}

var round_timer
var round_time = 20
var round_number = 2
var round_count = 0
var sudden_death=false
var best_of = 5
#
var winner_ran_once = false
var player_to_add_score = null
var player_pos_indexes = {}
var scores = {}
var first_run=true


onready var scoreboard_start_pos = $Scoreboard.rect_global_position

var map_folder="res://Assets/World/Maps/"

func create_scores():
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		scores[p.player_name]=0


func _process(delta):
	if (first_run):
		first_run = false
		create_scores()
		initialise_scoreboard()
		create_round_timer()
	
	if(scoreboard_sliding):
		slide(delta)
	
	if(shake > 0 and !scoreboard_sliding):
		shake -= 1
		shake_scoreboard()
	else:
		scoreboard_start_pos = $Scoreboard.rect_global_position
	
	#If the host:
	if(get_tree().is_network_server()):
		#Check if one player is left
		var one_player_left = detect_players_left()
		if(one_player_left):
			if(!winner_ran_once):
				if(len(get_tree().get_nodes_in_group("player"))>1):
					var last_player = get_last_player()
					rpc("increase_score",last_player)
				var winner = check_for_winner()
				if(!winner):
					show_scoreboard()
					#restart_round()
					rpc("show_scoreboard")
				else:
					rpc("show_result_message")
				winner_ran_once = true	
				

sync func show_scoreboard():

	print("OK")
	open_scoreboard()
	update_scoreboard()
	$Scoreboard/scoreboardEnd/colourSplash.playing = true
	$Scoreboard/scoreboardEnd/colourSplash.visible = true 

	shake = 100
	$RestartRoundTimer.start(5)

func open_scoreboard():
	scoreboard_sliding = true
	scoreboard_open = true

func close_scoreboard():
	scoreboard_sliding = true
	scoreboard_open = false

func slide(delta):
	var slide_y = 0
	var mul = 1
	if(scoreboard_open):
		mul = -1
		slide_y = 150
	else:
		mul = 1
		slide_y = -300
	if(slide_speed < slide_max_speed):
		slide_speed += slide_accel*delta 
	$Scoreboard.rect_global_position.y -= slide_speed*mul
	#stop when arrived
	if(scoreboard_open):
		if(($Scoreboard.rect_global_position.y < (slide_y+$Scoreboard.rect_global_position.y*0.5) and
			$Scoreboard.rect_global_position.y > (slide_y-$Scoreboard.rect_global_position.y*0.5))):#:
			$Scoreboard.rect_global_position.y = slide_y
			print("OH")
			slide_speed = 0
			scoreboard_sliding = false
	elif($Scoreboard.rect_global_position.y < (slide_y+$Scoreboard.rect_global_position.y*0.5)):
		print("AH")
		slide_speed = 0
		scoreboard_sliding = false


sync func show_result_message():
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if(p.network_handler.is_network_master()):
			show_scoreboard()
			$EndGameTimer.start()
			break
			#else:
			#	$LoseSprite.visible = true
			#	break

func check_for_winner():
	for key in scores:
		if scores[key]==best_of:
			return true
	return false

sync func increase_score(name):
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if(p.player_name == name):
			$Scoreboard/scoreboardEnd/colourSplash.modulate = gamestate.colours[gamestate.players_colour[p.my_id]]
	scores[name]+=1
	player_to_add_score = name
	
func detect_players_left():
	var players_left = 0
	var players = get_tree().get_nodes_in_group("player")
	#if more than one player
	if(len(players) > 1):
		for p in players:
			if(p.get_network_handler().remote_dead == false):
				players_left += 1
		if(players_left == 1):
			return true
		return false
	else:
		return players[0].get_node("NetworkHandler").remote_dead

func get_last_player():
	var players = get_tree().get_nodes_in_group("player")
	if(len(players) == 1):
		return players[0].player_name
	for p in players:
			if(p.get_network_handler().remote_dead == false):
				return p.player_name

sync func play_countdown():
	round_timer.set_paused(true)
	pause_players(true)
	for i in range(3,0,-1):
		get_node("Number"+str(i)).visible = true
		get_node("Number"+str(i)).playing = true
		yield(get_tree().create_timer(1.0), "timeout")
		get_node("Number"+str(i)).visible = false
		get_node("Number"+str(i)).playing = false
	pause_players(false)
	round_timer.set_paused(false)

func get_player_count():
	return len(get_tree().get_nodes_in_group("player"))

func pause_players(yes):
	for o in get_tree().get_nodes_in_group("player"):
		o.set_paused(yes)

func restart_round():
	rpc("load_world","hole")
	#Because we dont want to restart the scene, we need to call all reset functions
	#in objects that may have changed.
	
	#All objects that can be reset will be put in the resettable group
	#all objects in resettable should have a reset function
	if get_tree().is_network_server():
		for o in get_tree().get_nodes_in_group("resettable"):
			o.rpc("reset") 
		rpc("play_countdown")

func _on_Void_player_fell(dead_player,killing_player):
	if(get_tree().is_network_server()):
		rpc("update_score",killing_player)

remote func update_score(player):
	if(player==""):
		print("a player ended their own suffering")
	update_scoreboard()

func _input(event):
	if event.is_action_pressed("scoreboard"):
		#$Scoreboard.visible = true
		open_scoreboard()
	elif event.is_action_released("scoreboard"):
		#$Scoreboard.visible = false
		close_scoreboard()

func initialise_scoreboard():
	var play_num = get_player_count()
	var endMaxYValues = [36, 72, 108, 144]
	$Scoreboard/scoreboardEnd.transform.origin.y = endMaxYValues[play_num-1]
	
	print(play_num)
	#Add the player rects for names
	if(play_num > 1):
		var j = 2
		while j <= play_num:
			print("Scoreboard/playerRect"+str(j))
			get_node("Scoreboard/playerRect"+str(j)).visible = true
			j+=1
	var i = 1
	for player in scores.keys():
		player_pos_indexes[player] = i
		get_node("Scoreboard/PlayerNames/Player"+str(i)).text = player
		get_node("Scoreboard/PlayerScores/Player"+str(i)).text = str(scores[player])
		i+=1
		
	#Set up to where the best of numbers show
	for b in range(best_of, 9):
		get_node("Scoreboard/" + str(b+1)).modulate = Color("262b44")

func update_scoreboard():
	var i = 1
	for player in scores.keys():
		get_node("Scoreboard/PlayerScores/Player"+str(i)).text = str(scores[player])
		i+=1

func add_to_scoreboard(player):
	if(player != null):
		var colour = 0
		var players = get_tree().get_nodes_in_group("player")
		for p in players:
			if(p.player_name == player):
				colour = gamestate.colours[gamestate.players_colour[p.my_id]]

		var score_square_positions = [3, 15, 27, 39, 51, 63, 75, 87, 99]
		var y_values = [24, 30, 48, 66, 84]
		var index = player_pos_indexes[player]
		print("SCORE! with player id of ?" + str(player))
		var score_box = load("res://scoreBox.tscn").instance()
		if(!player_scoreboxes.has(player)):
			player_scoreboxes[player] = []
		player_scoreboxes[player].append(score_box)
		for p in players:
			if(scores[p.player_name]==best_of):
				var winner_index = player_pos_indexes[player]
				$Scoreboard/aWinner.visible = true
				if(best_of < 4):
					$Scoreboard/aWinner.rect_position = Vector2(rect_position.x+80,y_values[winner_index]-8)
				else:
					$Scoreboard/aWinner.rect_position = Vector2(rect_position.x+40,y_values[winner_index]-8)
				for sb in player_scoreboxes[p.player_name]:
					sb.modulate = gamestate.colours[gamestate.players_colour[p.my_id]]
		score_box.z_index = -100
		get_tree().get_root().get_node("World/RoundController/Scoreboard").add_child(score_box)
		print(y_values[index])
		score_box.init(100, y_values[index], score_square_positions[scores[player]-1],y_values[index],colour) 

func shake_scoreboard():
	var random_dir = rand_range(0,2*PI)
	var dist = 0.6
	var new_vector = scoreboard_start_pos + Vector2(cos(random_dir)*dist,sin(random_dir)*dist)
	$Scoreboard._set_global_position(new_vector)

func start_sudden_death():
	pass

func create_round_timer():
	round_timer = Timer.new()
	round_timer.set_wait_time(round_time)
	round_timer.set_one_shot(true)
	round_timer.connect("timeout",self,"_round_timer_timeout")
	add_child(round_timer)
	round_timer.start()

func create_fall_timer():
	fall_timer = Timer.new()
	fall_timer.set_wait_time(fall_time)
	fall_timer.connect("timeout",self,"pick_map_section")
	add_child(fall_timer)
	fall_timer.start()

func _round_timer_timeout():
	sudden_death = true
	create_fall_timer()
	
func pick_map_section():
	if(!get_tree().is_network_server()):
		return
	var remainingPieces = []
	for x in range(len(fall_map)):
		for y in range(len(fall_map[0])):
			if fall_map[x][y]==1:
				remainingPieces.append([x,y])
	var r = RandomNumberGenerator.new()
	r.randomize()
	var pair = remainingPieces[r.randi_range(0,len(remainingPieces)-1)]
	fall_map[pair[0]][pair[1]] = 0
	decrease_pos(pair[0]+1,pair[1])
	decrease_pos(pair[0]-1,pair[1])
	decrease_pos(pair[0],pair[1]+1)
	decrease_pos(pair[0],pair[1]-1)
#	print(get_node("../Environment/Towers/TowerPiece"+str((pair[0]*8+pair[1])+1)))
	get_node("../Environment/Towers/TowerPiece"+str((pair[0]*8+pair[1])+1)).rpc("begin_fall")

func decrease_pos(x,y):
	if x<len(fall_map) and y < len(fall_map[0]):
		if fall_map[x][y]==2:
			fall_map[x][y] = 1

func _on_ResetButton_pressed():
	if(get_tree().is_network_server()):
		$Scoreboard.visible = false
		restart_round()


func _on_colourSplash_animation_finished():
	add_to_scoreboard(player_to_add_score)
	$Scoreboard/scoreboardEnd/colourSplash.visible = false
	$Scoreboard/scoreboardEnd/colourSplash.playing = false
	$Scoreboard/scoreboardEnd/colourSplash.frame = 0


func _on_RestartRoundTimer_timeout():
	print("OH YEAH THE TIMER IS DONE")
	close_scoreboard()
	$RestartRoundTimer.stop()
	if(get_tree().is_network_server()):
		restart_round()
	winner_ran_once = false


func print_world():
	var fstr = '{"type":{type},},'
	for o in get_tree().get_nodes_in_group("Removable"):
		pass

#-------------
#I would like to apologise to Donald Knuth and God for this abomination of a function.
#-------------
sync func load_world(map_name):
	#delete old world
	for o in get_node("../Environment/Towers").get_children():
		if o.is_in_group("faketower"):
			continue
		o.set_name("dead_tower")
		o.remove_world_props()
		o.queue_free()
	#create new world
	var map_file = File.new()
	assert(map_file.file_exists(map_folder+map_name+".json"),"MAP FILE "+map_folder+map_name+".json"+" NOT FOUND")
	map_file.open(map_folder+map_name+".json",File.READ)
	var map_data = parse_json(map_file.get_line())
	var start_x = map_data["start_x"]
	var start_y = map_data["start_y"]
	fall_map = map_data["fall_map"]
	var tower_scene = load("res://Assets/World/Tower/Tower.tscn")
	for x in range(len(fall_map)):
		for y in range(len(fall_map[0])):
			var new_tower = tower_scene.instance()
			if fall_map[x][y]==0:
				continue
			#NOTE THAT DESPITE THE USE OF Y IN THE CODE WE 
			#ACTUALLY ARE CHANGING THE Z COORDINATE
			new_tower.transform.origin.z = start_y+x*2.55
			new_tower.transform.origin.x = start_x+y*2.55
			new_tower.scale.x = 0.8
			new_tower.scale.z = 0.8
			get_node("../Environment/Towers").add_child(new_tower)
			new_tower.set_name("TowerPiece"+str(x*len(fall_map[0])+y+1))
	#grass loading
	var grass_path = "res://Assets/World/Grass/"
	for grass_data in map_data["grass_flat"]:
		var grass = load(grass_path+grass_data["type"]+".tscn").instance()
		match grass_data["type"]:
			"GrassFront1","GrassFront2":
				pass
			"FlatGrass1","FlatGrass2","FlatGrass3":
				#print("this worked")
				if grass_data["type"]=="FlatGrass1":
					grass.transform.origin.y = -0.85
				elif grass_data["type"]=="FlatGrass2":
					grass.transform.origin.y = 0.15
				else:
					grass.transform.origin.y = 0.1
				grass.transform.origin.z = start_y+grass_data["pos_x"]*2.55
				grass.transform.origin.x = start_x+grass_data["pos_y"]*2.55
				grass.scale.x = 0.5
				grass.scale.y = 0.5
				grass.scale.z = 0.5
				grass.rotation_degrees.y = grass_data["rot"]
		get_node("../Environment/FlatGrass").add_child(grass)
		for node in get_node("../Environment/FlatGrass").get_children():
			#print(node.get_name(),node.transform.origin.x)
			pass

	for obj_data in map_data["pink_flowers"]:
		var new_obj = load(grass_path+"PinkFlower.tscn").instance()
		get_node("../Environment/Grass").add_child(new_obj)
		new_obj.global_transform.origin.x = obj_data["pos_x"]
		new_obj.global_transform.origin.y = obj_data["pos_y"]
		new_obj.global_transform.origin.z = obj_data["pos_z"]
		new_obj.scale.x = obj_data["sc_x"]
		new_obj.scale.y = obj_data["sc_y"]
		new_obj.scale.z = obj_data["sc_x"]
		new_obj.rotation_degrees.y = obj_data["rot"]
	
	for obj_data in map_data["blue_flowers"]:
		var new_obj = load(grass_path+"BlueFlower.tscn").instance()
		get_node("../Environment/Grass").add_child(new_obj)
		new_obj.global_transform.origin.x = obj_data["pos_x"]
		new_obj.global_transform.origin.y = obj_data["pos_y"]
		new_obj.global_transform.origin.z = obj_data["pos_z"]
		new_obj.scale.x = obj_data["sc_x"]
		new_obj.scale.y = obj_data["sc_y"]
		new_obj.scale.z = obj_data["sc_x"]
		new_obj.rotation_degrees.y = obj_data["rot"]
	
	for obj_data in map_data["grass_blades"]:
		var new_obj = load("res://Assets/World/Tall Grass/TallGrass.tscn").instance()
		get_node("../Environment/Grass").add_child(new_obj)
		new_obj.global_transform.origin.x = obj_data["pos_x"]
		new_obj.global_transform.origin.y = obj_data["pos_y"]
		new_obj.global_transform.origin.z = obj_data["pos_z"]
		new_obj.scale.x = obj_data["sc_x"]
		new_obj.scale.y = obj_data["sc_y"]
		new_obj.scale.z = obj_data["sc_x"]
		new_obj.rotation_degrees.y = obj_data["rot"]

func _on_EndGameTimer_timeout():
	get_tree().get_root().get_node("World").queue_free() 
	var world = load("res://Menu/lobby.tscn").instance()
	get_tree().get_root().add_child(world)
	world.get_node("Lobby").trans_to_players()
	
