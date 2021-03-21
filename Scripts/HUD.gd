extends Control

var seconds = 0
var total_score = 0

func _ready():
	$TimeSeconds.text = String(seconds)
	$ActualScore.text = String(total_score)
	
	var fish = get_tree().get_root().get_node("BaseGame/Pond")
	fish.connect("add_to_score", self, "add_to_score")
	
func _on_SecondTimer_timeout():
	seconds += 1
	$TimeSeconds.text = String(seconds)

func add_to_score(score):
	total_score = int(total_score) + int(score)
	update_score()
	pass
	
func update_score():
	$ActualScore.text = String(total_score)
