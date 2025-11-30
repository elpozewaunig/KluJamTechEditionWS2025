extends Node3D

@onready var gun_ray = $RayCast3D
var missile_scene = load("res://scenes/Missile.tscn")

func _process(_delta):
	# Input Guard
	if not owner.is_multiplayer_authority():
		return
		
	if Input.is_action_just_pressed("shoot"):
		request_fire()

func request_fire():
	# Gather data
	var pos = gun_ray.global_position
	var rot = gun_ray.global_transform.basis
	var is_host = (owner.name == "1")
	
	if multiplayer.is_server():
		# If I am Host, tell everyone (including myself) to spawn
		rpc("fire_event", pos, rot, is_host)
	else:
		# If I am Client, ask Server to broadcast the fire event
		rpc_id(1, "request_fire_from_client", pos, rot, is_host)

# Server receives Client's request, verifies it, and broadcasts to everyone
@rpc("any_peer", "call_local")
func request_fire_from_client(pos, rot, is_host):
	if multiplayer.is_server():
		# You could add anti-cheat checks here (e.g. check fire rate)
		rpc("fire_event", pos, rot, is_host)

# THIS RUNS ON EVERYONE (Host and Client)
@rpc("call_local", "reliable")
func fire_event(pos, rot, is_host):
	var missile = missile_scene.instantiate()
	
	# Add to the Level scene so it doesn't move with the player
	get_node("/root/LevelScene/Bullets").add_child(missile)
	
	# Setup immediately
	missile.setup_missile(pos, rot, is_host)
