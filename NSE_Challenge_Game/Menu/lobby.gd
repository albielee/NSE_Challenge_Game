extends Control

enum {
	JOIN,
	HOST,
	EXIT,
	MENU,
	OPTIONS,
	PLAYERS
}
var transition = null
var game_started = false
onready var l_cam = get_parent().get_node("Camera")

func _ready():
	# Called every time the node is added to the scene.
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("game_ended", self, "_on_game_ended")
	gamestate.connect("game_error", self, "_on_game_error")
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		$Connect/Name.text = OS.get_environment("USERNAME")
		$Menu/Host/Hosting/Name.text = OS.get_environment("USERNAME")
	else:
		var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
		$Connect/Name.text = desktop_path[desktop_path.size() - 2]
		$Menu/Host/Hosting/Name.text = desktop_path[desktop_path.size() - 2]

func _process(delta):
	if(!get_tree().get_root().get_node("LobbyWorld/MenuTheme").is_playing()):
		get_tree().get_root().get_node("LobbyWorld/MenuTheme").play()
	if(game_started):
		if(!l_cam.travelling):
			#Setup round settings for starting the game
			var roundSettings = []
			roundSettings.append($Players/MapSelector/Label.text)
			if $Players/BestOf.text.is_valid_integer():
				roundSettings.append(int($Players/BestOf.text))
			else:
				roundSettings.append(5)
	
			#if $Players/RoundNumber.text.is_valid_integer():
			#	roundSettings.append(int($Players/RoundNumber.text))
			#else:
			#	roundSettings.append(5)
			gamestate.begin_game(roundSettings)
			

func _on_host_pressed():
	if $Menu/Host/Hosting/Name.text == "":
		$Menu/Host/Hosting/ErrorLabel.text = "Invalid name!"
		return
	
	var ip = $Menu/Host/Hosting/IPAddress.text
	if not ip.is_valid_ip_address():
		$Menu/Host/Hosting/ErrorLabel.text = "Invalid IP address!"
		return
	
	$Menu/Host.hide()
	$Menu.hide()
	transition = PLAYERS
	play_transition_animation("players", false)
	
	$Menu/Host/Hosting/ErrorLabel.text = ""
	
	var player_name = $Menu/Host/Hosting/Name.text
	gamestate.host_game(player_name)
	refresh_lobby()

func trans_to_players():
	#$Menu/Host.hide()
	$Menu.hide()
	$Players.show()
	transition = PLAYERS
	refresh_lobby()

func _on_join_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return
	
	var ip = $Connect/IPAddress.text
	if not ip.is_valid_ip_address():
		$Connect/ErrorLabel.text = "Invalid IP address!"
		return
	#$Connect/join.disabled = true
	#$Menu/Host/Hosting/host.disabled = true
	
	var player_name = $Connect/Name.text
	gamestate.join_game(ip, player_name)

func disable_buttons():
	for button in get_tree().get_nodes_in_group("button"):
		button.disabled = true

func _on_connection_success():
	$Connect/ErrorLabel.text = ""
	$Connect.hide()
	$Menu.hide()
	transition = PLAYERS
	play_transition_animation("players", false)
	$Connect.hide()
	$Players.show()

func _on_connection_failed():
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed.")

func _on_game_ended():
	show()
	$Connect.show()
	$Players.hide()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false

func _on_game_error(errtxt):
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered_minsize()
	disable_buttons()

func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	$Players/List.clear()
	$Players/List.add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		$Players/List.add_item(p)
	
	#Disable host only features of the lobby
	var notHost = not get_tree().is_network_server()
	$Players/Start.disabled = notHost
	$Players/MapSelector/ButtonLeft.disabled = notHost
	$Players/MapSelector/ButtonRight.disabled = notHost

func _on_HostButton_pressed():
	$Menu/Main.hide()
	transition = HOST
	play_transition_animation("host", false)

func _on_JoinButton_pressed():
	$Menu/Main.hide()
	transition = JOIN
	play_transition_animation("join", false)

func _on_TransitionAnims_animation_finished():
	$TransitionAnims.hide()
	$TransitionAnims.playing = false
	$TransitionAnims.frame = 0
	
	if(transition == JOIN):
		$Connect.show()
	elif(transition == HOST):
		$Menu/Host.show()
	elif(transition == PLAYERS):
		$Players.show()
	elif(transition == OPTIONS):
		$Menu/Options.show()
	elif(transition == MENU):
		$Menu/Main.show()
		$Menu.show()
	
func play_transition_animation(anim_name, backwards):
	if(backwards):
		$TransitionAnims.frame = 6
	$TransitionAnims.show()
	$TransitionAnims.play(anim_name, backwards)
	
func _on_ExitButton_pressed():
	#close the game
	get_tree().quit()

func _on_OptionsButton_pressed():
	$Menu/Main.hide()
	transition = OPTIONS
	play_transition_animation("options", false)

func _on_BackButton_pressed():
	$Menu/Options.hide()
	$Connect.hide()
	$Menu/Host.hide()
	$Players.hide()
	if(transition == JOIN):
		play_transition_animation("join", true)
	elif(transition == HOST):
		play_transition_animation("host", true)
	elif(transition == OPTIONS):
		play_transition_animation("options", true)
	elif(transition == PLAYERS):
		play_transition_animation("players", true)

	transition = MENU

func _on_Start_pressed():
	$Players.visible = false
	$Title.visible = false
	
	gamestate.notify_clients_start_pressed()
	game_started = true
	l_cam.start_travelling()
	

func _on_LeaveButton_pressed():
	gamestate.player_leave_button()


