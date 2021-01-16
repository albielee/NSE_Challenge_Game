extends Node2D


#When the game first loads, set things that need to be first loaded...
func _ready():
	
	#This grabs the focus of the play button on the menu screen when first loading into the game,
	#allow tabbing through the buttons thus no need for a mouse
	get_node("TitleScreen/Menu/CentreRow/Buttons/Play").grab_focus()

