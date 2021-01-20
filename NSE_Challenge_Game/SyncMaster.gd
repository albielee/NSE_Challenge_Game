extends Node


var settings = Settings
puppet var puppetTransform = Transform2D();

func _process(delta):
	#Sync all syncObjects at tickrate speed (e.g. rocks updating 64 time a second)
	#All objects that need to be synced are put into the group "syncObject"
	var tickrate = settings.tickrate;
	for o in get_tree().get_nodes_in_group("syncObject"):
		

		if not is_network_master():
			#set to kinematic body
			o.set_mode(3);
			o.transform = puppetTransform;
		else:
			rset("puppetTransform", o.transform);
