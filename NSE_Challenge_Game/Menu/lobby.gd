extends Control

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

func _on_host_pressed():
	if $Menu/Host/Hosting/Name.text == "":
		$Menu/Host/Hosting/ErrorLabel.text = "Invalid name!"
		return
	
	var ip = $Menu/Host/Hosting/IPAddress.text
	if not ip.is_valid_ip_address():
		$Menu/Host/Hosting/ErrorLabel.text = "Invalid IP address!"
		return
	
	$Menu/Host.hide()
	$Players.show()
	$Menu/Host/Hosting/ErrorLabel.text = ""
	
	var player_name = $Menu/Host/Hosting/Name.text
	gamestate.host_game(player_name)
	$Players/ColourSelection.badcodebuticantbefuckeditworks()
	refresh_lobby()

func _on_join_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return
	
	var ip = $Connect/IPAddress.text
	if not ip.is_valid_ip_address():
		$Connect/ErrorLabel.text = "Invalid IP address!"
		return
	
	$Connect/ErrorLabel.text = ""
	$Connect.hide()
	$Players.show()
	$Connect/Join.disabled = true
	$Menu/Host/Hosting/StartServerButton.disabled = true
	
	var player_name = $Connect/Name.text
	gamestate.join_game(ip, player_name)

func disable_buttons():
	for button in get_tree().get_nodes_in_group("button"):
		button.disabled = true

func _on_connection_success():
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
	$Menu/Host.show()

func _on_JoinButton_pressed():
	$Menu/Main.hide()
	$Connect.show()

func _on_ExitButton_pressed():
	#close the game
	get_tree().quit()

func _on_OptionsButton_pressed():
	$Menu/Main.hide()
	$Menu/Options.show()

func _on_BackButton_pressed():
	$Menu/Options.hide()
	$Connect.hide()
	$Menu/Host.hide()
	$Menu/Main.show()

func _on_Start_pressed():
	#Setup round settings for starting the game
	var roundSettings = []
	roundSettings.append($Players/MapSelector/Label.text)
	
	gamestate.begin_game(roundSettings)


