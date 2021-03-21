extends Node2D

signal add_to_score

const Fish = preload("res://Scenes/Fish.tscn")

var Fishes = []

var nextPossiblePosition = Vector2(10,10)

func _ready():
	
	Fishes = []
	
	new_pond()
	
	for fish in Fishes:
		fish.connect("caught", self, "add_to_score")
		
	randomize()
	pass

func new_pond():
	for x in 4:
		for y in 5:
			var newFish = new_fish("random")
			newFish.position = nextPossiblePosition
			Fishes.append(newFish)
			add_child(newFish)
			nextPossiblePosition.x += 34
			nextPossiblePosition.x += randi() % 10
		nextPossiblePosition.x = 10
		nextPossiblePosition.y += 34
	
func new_fish(type):
	var fish = Fish.instance()
	# random fish
	return fish

func add_to_score(score):
	emit_signal("add_to_score", score)
	pass
