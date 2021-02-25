extends TextureButton

onready var anim = $Anim

var mouse_entered = false

func _on_JoinButton_focus_entered():
	anim.frame = 0
	anim.play("focused")

func _on_JoinButton_focus_exited():
	anim.frame = 0
	anim.play("unfocused")

func _on_JoinButton_button_down():
	anim.frame = 0
	anim.play("focused")

func _on_Join_animation_finished():
	if(anim.animation == "hover"):
		if(mouse_entered):
			anim.frame = 5
		else:
			anim.frame = 0
			anim.play("unfocused")

func _on_JoinButton_mouse_entered():
	mouse_entered = true
	anim.frame = 0
	anim.play("hover")

func _on_JoinButton_mouse_exited():
	mouse_entered = false
	if(anim.animation == "hover"):
		anim.play("hover", true)
	else:
		anim.frame = 0
		anim.play("unfocused")
