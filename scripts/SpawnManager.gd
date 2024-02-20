extends Node2D

@export var node2D: Node2D

var rng = RandomNumberGenerator.new()
var available_units = []
var CPU_units = []
var USER_units = []

var open_tiles = []
var random = []

var zombie = preload("res://scenes/sprites/zombie.scn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func spawn_zombies():
	# Find open tiles
	open_tiles.clear()	
	for i in 16:
		for j in 16:
			if get_node("../TileMap").astar_grid.is_point_solid(Vector2i(i,j)) == false:			
				open_tiles.append(Vector2i(i,j))
	
	random.clear()
	random = get_random_numbers(0, open_tiles.size())

	# Drop zombies at start	
	for i in 4:	
		var zomb = zombie.instantiate()
		node2D.add_child(zomb)
		zomb.add_to_group("zombies")			
		var new_position = get_node("../TileMap").map_to_local(open_tiles[random[i]]) + Vector2(0,0) / 2
		zomb.position = Vector2(new_position.x, new_position.y-500)
		var tween: Tween = create_tween()
		tween.tween_property(zomb, "position", new_position, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
		get_node("../TileMap").astar_grid.set_point_solid(new_position, true)
		await get_tree().create_timer(0.5).timeout
									

	
func get_random_numbers(from, to):
	var arr = []
	for i in range(from,to):
		arr.append(i)
	arr.shuffle()
	return arr	


func _on_spawn_button_pressed():
	await spawn_zombies()
	get_node("../TileMap").zombie_attack_ai()
