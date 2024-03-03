extends Node2D

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	var num = rng.randi_range(0,2)
	if num == 1:
		self.show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
