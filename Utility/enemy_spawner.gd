extends Node2D


@export var spawns: Array[Spawn_info] = []

@onready var player = get_tree().get_first_node_in_group("player")

var time = 0

signal changetime(time)

func _ready():
	connect("changetime",Callable(player,"change_time"))
	

func _on_timer_timeout():
	time += 1
	var enemy_spawns = spawns
	for i in enemy_spawns:
		if time >= i.time_start and time <= i.time_end:
			if i.spawn_delay_counter < i.enemy_spawn_delay:
				i.spawn_delay_counter += 1
			else:
				i.spawn_delay_counter = 0
				var new_enemy = load(str(i.enemy.resource_path))
				var counter = 0
				while counter < i.enemy_number:
					var enemy_spawn = new_enemy.instantiate()
					enemy_spawn.global_position = get_random_position()
					add_child(enemy_spawn)
					counter += 1
	emit_signal("changetime",time)
			
		

func get_random_position(up = true, down = true, left = true, right = true):
	var vpr = get_viewport_rect().size * randf_range(1.1, 1.4)
	var top_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y - vpr.y/2)
	var bottom_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y + vpr.y/2)
	var pos_side = []
	if up:
		pos_side.append("up")
	if down:
		pos_side.append("down")
	if right:
		pos_side.append("right")
	if left:
		pos_side.append("left")
	
	var get_rand = randi() % pos_side.size()
	var spawn_pos1 = Vector2.ZERO
	var spawn_pos2 = Vector2.ZERO
	
	match pos_side[get_rand]:
		"up":
			spawn_pos1 = top_left
			spawn_pos2 = Vector2(bottom_right.x, top_left.y)
		"down":
			spawn_pos1 = Vector2(top_left.x, bottom_right.y)
			spawn_pos2 = bottom_right
		"right":
			spawn_pos1 = Vector2(bottom_right.x, top_left.y)
			spawn_pos2 = bottom_right
		"left":
			spawn_pos1 = top_left
			spawn_pos2 = Vector2(top_left.x, bottom_right.y)
	
	var x_spawn = randf_range(spawn_pos1.x, spawn_pos2.x)
	var y_spawn = randf_range(spawn_pos2.y, spawn_pos2.y)
	return Vector2(x_spawn,y_spawn)
	
