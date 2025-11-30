extends Node3D

@onready var gun_ray = $RayCast3D
# Ensure this points to the new PHYSICS-ONLY missile (no sync node)
var missile_scene = load("res://scenes/Missile.tscn")

func _process(_delta):
	# Input Guard
	if not owner.is_multiplayer_authority():
		return
		
	if Input.is_action_just_pressed("shoot"):
		request_fire()

func request_fire():
	var pos = gun_ray.global_position
	var rot = gun_ray.global_transform.basis
	var is_host = (owner.name == "1")
	
	if multiplayer.is_server():
		# I am Host: Broadcast directly
		rpc("fire_event", pos, rot, is_host)
	else:
		# I am Client: Ask Server to broadcast
		rpc_id(1, "request_fire_from_client", pos, rot, is_host)

# -------------------------------------------------------------
# 1. THE REQUEST (Runs on Server)
# "any_peer" allows the Client to call this on the Server
# -------------------------------------------------------------
@rpc("any_peer", "call_local")
func request_fire_from_client(pos, rot, is_host):
	# Security check: Only run this if I am the server
	if multiplayer.is_server():
		# Broadcast to everyone
		rpc("fire_event", pos, rot, is_host)

# -------------------------------------------------------------
# 2. THE EVENT (Runs on Everyone)
# "any_peer" is CRITICAL here! 
# It allows the Server (ID 1) to execute this function on the 
# Client's machine (ID 12345), even though the Client owns the node.
# -------------------------------------------------------------
@rpc("any_peer", "call_local")
func fire_event(pos, rot, is_host):
	var missile = missile_scene.instantiate()
	
	# Add to Level so it doesn't move with the ship
	get_node("/root/LevelScene/Bullets").add_child(missile)
	
	# Setup physics immediately
	if missile.has_method("setup_missile"):
		missile.setup_missile(pos, rot, is_host)
