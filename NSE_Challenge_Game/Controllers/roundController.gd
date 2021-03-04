extends Control

onready var countdown_sprites = [$Number3,$Number2,$Number1]

var fall_map = [
	[1,1,1,1,1,1,1,1],
	[1,1,1,1,1,1,1,1],
	[1,1,1,0,0,1,1,1],
	[1,1,1,0,0,1,1,1],
	[1,1,1,0,0,1,1,1],
	[1,1,1,0,0,1,1,1],
	[1,1,1,1,1,1,1,1],
	[1,1,1,1,1,1,1,1]
]

var fall_time = 5
var fall_timer



var round_timer
var round_time = 20
var round_number = 5
var round_count = 0
var sudden_death=false


var scores = {}
var first_run=true
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
		
	#If the host:
	if(get_tree().is_network_server()):
		#Check if one player is left
		var one_player_left = detect_players_left()
		if(one_player_left):
			var last_player = get_last_player()
#			scores[last_player]+=1
			restart_round()

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
	pass

func play_countdown():
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

func pause_players(yes):
	for o in get_tree().get_nodes_in_group("player"):
		o.set_paused(yes)

func restart_round():
	#Because we dont want to restart the scene, we need to call all reset functions
	#in objects that may have changed.
	
	#All objects that can be reset will be put in the resettable group
	#all objects in resettable should have a reset function
	
	for o in get_tree().get_nodes_in_group("resettable"):
		o.rpc("reset") 
	play_countdown()

func _on_Void_player_fell(dead_player,killing_player):
	if(get_tree().is_network_server()):
		update_score(killing_player)
		rpc("update_score",killing_player)

remote func update_score(player):
	if(player==""):
		print("a player ended their own suffering")
	else:
		scores[player]+=1
		print(scores)
	update_scoreboard()

func _input(event):
	if event.is_action_pressed("scoreboard"):
		$Scoreboard.visible = true
	elif event.is_action_released("scoreboard"):
		$Scoreboard.visible = false

func initialise_scoreboard():
	var i = 1
	for player in scores.keys():
		get_node("Scoreboard/PlayerNames/Player"+str(i)).text = player
		get_node("Scoreboard/PlayerScores/Player"+str(i)).text = str(scores[player])
		i+=1

func update_scoreboard():
	var i = 1
	for player in scores.keys():
		get_node("Scoreboard/PlayerScores/Player"+str(i)).text = str(scores[player])
		i+=1

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
	var remainingPieces = []
	for x in range(len(fall_map)):
		for y in range(len(fall_map[0])):
			if fall_map[x][y]==1:
				remainingPieces.append([x,y])
	var r = RandomNumberGenerator.new()
	r.randomize()
	var pair = remainingPieces[r.randi_range(0,len(remainingPieces)-1)]
	fall_map[pair[0]][pair[1]] = 0
#	print(get_node("../Environment/Towers/TowerPiece"+str((pair[0]*8+pair[1])+1)))
	get_node("../Environment/Towers/TowerPiece"+str((pair[0]*8+pair[1])+1)).begin_fall()
	####make this work for multiplayer!!!!

func _on_ResetButton_pressed():
	if(get_tree().is_network_server()):
		$Scoreboard.visible = false
		restart_round()
