extends Control

var countdown_sprites = [$Number3,$Number2,$Number1]

var scores = {}
var first_run=true
func create_scores():
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		scores[p.player_name]=0


func _process(delta):
	#If the host:
	if(get_tree().is_network_server()):
		if (first_run):
			first_run = false
			create_scores()
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
	get_tree().paused = true
	for i in range(3,0,-1):
		get_node("Number"+str(i)).visible = true
		yield(get_tree().create_timer(1.0), "timeout")
		get_node("Number"+str(i)).visible = false
	get_tree().paused = false
		

func restart_round():
	#Because we dont want to restart the scene, we need to call all reset functions
	#in objects that may have changed.
	
	#All objects that can be reset will be put in the resettable group
	#all objects in resettable should have a reset function
	play_countdown()
	for o in get_tree().get_nodes_in_group("resettable"):
		o.rpc("reset")
		o.reset()
		pass
		
func _on_Void_player_fell(dead_player,killing_player):
	if(killing_player==""):
		print("a player ended their own suffering")
	else:
		scores[killing_player]+=1
		print(scores)
	pass # Replace with function body.
"""
OLD CODE BUT MAY BE USEFUL LATER

var player_labels = {}

func _process(_delta):
	var rocks_left = 1#$"../Rocks".get_child_count()
	if rocks_left == 0:
		var winner_name = ""
		var winner_score = 0
		for p in player_labels:
			if player_labels[p].score > winner_score:
				winner_score = player_labels[p].score
				winner_name = player_labels[p].name

		$"../Winner".set_text("THE WINNER IS:\n" + winner_name)
		$"../Winner".show()


sync func increase_score(for_who):
	assert(for_who in player_labels)
	var pl = player_labels[for_who]
	pl.score += 1
	pl.label.set_text(pl.name + "\n" + str(pl.score))


func add_player(id, new_player_name):
	var l = Label.new()
	l.set_align(Label.ALIGN_CENTER)
	l.set_text(new_player_name + "\n" + "0")
	l.set_h_size_flags(SIZE_EXPAND_FILL)
	var font = DynamicFont.new()
	font.set_size(18)
	font.set_font_data(preload("res://montserrat.otf"))
	l.add_font_override("font", font)
	add_child(l)

	player_labels[id] = { name = new_player_name, label = l, score = 0 }


func _ready():
	#$"../Winner".hide()
	set_process(true)


func _on_exit_game_pressed():
	gamestate.end_game()
"""



