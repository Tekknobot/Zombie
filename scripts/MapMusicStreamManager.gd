extends AudioStreamPlayer2D

var rng = RandomNumberGenerator.new()
@onready var Map : = $"../TileMap"
@export var map_music: Array[AudioStream]

# Called when the node enters the scene tree for the first time.
func _ready():
	var num = rng.randi_range(0,1)
	self.stream = self.map_music[num]
	self.play()	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
