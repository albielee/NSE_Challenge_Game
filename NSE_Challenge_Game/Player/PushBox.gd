extends Area

var knockback_vector = Vector3.ZERO
var rock = null
var playerorientation = Vector3.ZERO
var mouseang = Vector3.ZERO

onready var shape = $CollisionShape

func update():
	if (rock!=null):
		rock.angular_velocity(mouseang*5)

func _on_PushBox_area_entered(area):
	if (rock==null):
		rock=area
		rock.add_force(knockback_vector)
		rock.angular_velocity(mouseang*5)
		rock.in_zone() #This is setting the rock to "push mode"
	else:
		area.add_force(knockback_vector/2)

func update_mouse_angle(target_angle_y):
	if rock != null:
		var rotation_angle = wrapf(target_angle_y - rock.face, -PI/4, PI/4);
		
		mouseang = Vector3.UP * rotation_angle;

func release():
	rock.out_zone() #Set rock directly back to "normal mode"
	rock = null
