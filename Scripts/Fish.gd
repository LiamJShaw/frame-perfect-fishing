extends Area2D

signal caught

var score = 10

func caught():
	report_score(score)
	queue_free()
	
func report_score(score):
	emit_signal("caught", score)
